-- ============================================================
-- Notes:
--   OUT  Rsrc  : same fix – swap_or_1op drives read-addr mux to Rsrc1
--
--   RET        : 4 cycles
--   INT index  : 8 cycles
--   RTI        : 7 cycles
--   Ext INT    : 7 cycles
--
--   BRANCH PENALTY - Conditional branches resolved in EX2
--     The flush signal (if_id_flush and id_ex1_flush) flushes
--     TWO stages (IF/ID and ID/EX1) instead of one
-- ============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY control_unit IS
    PORT (
        opcode       : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        clk, int, reset : IN STD_LOGIC;

        ---- Fetch signals
        popped_pc    : OUT STD_LOGIC;
        pc_en        : OUT STD_LOGIC;

        imm_jump              : OUT STD_LOGIC;
        jmp_cond_or_none      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        ---- Decode / pipeline-register enables
        if_id_enable   : OUT STD_LOGIC;
        if_id_flush    : OUT STD_LOGIC;  -- flush IF/ID (branch taken)
        id_ex1_flush   : OUT STD_LOGIC;

        swap_or_1op    : OUT STD_LOGIC;
        wb_address_sel : OUT STD_LOGIC;

        ---- control signals ----
        mem_write_sel           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        wb_enable               : OUT STD_LOGIC;
        output_sel              : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_or_mem              : OUT STD_LOGIC;
        is_push                 : OUT STD_LOGIC;
        sp_write_enable         : OUT STD_LOGIC;
        mem_read_write_enable   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_addr_sel            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_src_sel             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_func                : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        alu_mem_wb_sel          : OUT STD_LOGIC;
        ccr_enable              : OUT STD_LOGIC;
        swap_out                : OUT STD_LOGIC;
        idx_popped_pc_immediate_out : OUT STD_LOGIC;
        ext_int_read_m1         : OUT STD_LOGIC
    );
END ENTITY control_unit;

ARCHITECTURE behavioral OF control_unit IS

    -- Multi-cycle instruction state counters
    SIGNAL swap_counter    : STD_LOGIC  := '0';
    SIGNAL ret_counter     : INTEGER    := 0;  -- 0..4
    SIGNAL int_idx_counter : INTEGER    := 0;  -- 0..7
    SIGNAL rti_counter     : INTEGER    := 0;  -- 0..6
    SIGNAL ext_int_counter : INTEGER    := 0;
    SIGNAL ext_int_active  : STD_LOGIC  := '0';

    -- Internal delayed signals for popped_pc
    SIGNAL popped_pc_immediate  : STD_LOGIC := '0';
    SIGNAL popped_pc_delayed    : STD_LOGIC := '0';
    SIGNAL popped_pc_delayed_2  : STD_LOGIC := '0';
    SIGNAL idx_popped_pc_imm    : STD_LOGIC := '0';
    SIGNAL idx_delayed_1        : STD_LOGIC := '0';
    SIGNAL idx_delayed_2        : STD_LOGIC := '0';
    SIGNAL idx_delayed_3        : STD_LOGIC := '0';
    SIGNAL ext_int_popped_pc    : STD_LOGIC := '0';
    SIGNAL ext_int_read_m1_int  : STD_LOGIC := '0';

    SIGNAL ret_counter_sig      : INTEGER   := 0;

BEGIN
    -- Sequential counter
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN

            -- SWAP counter
            IF opcode = "01001" THEN
                swap_counter <= NOT swap_counter;
            ELSE
                swap_counter <= '0';
            END IF;

            -- RET counter
            IF opcode = "11101" THEN
                IF ret_counter < 4 THEN
                    ret_counter <= ret_counter + 1;
                ELSE
                    ret_counter <= 0;
                END IF;
            ELSE
                ret_counter <= 0;
            END IF;

            -- INT index counter
            IF opcode = "11110" THEN
                IF int_idx_counter < 7 THEN
                    int_idx_counter <= int_idx_counter + 1;
                ELSE
                    int_idx_counter <= 0;
                END IF;
            ELSE
                int_idx_counter <= 0;
            END IF;

            -- RTI counter
            IF opcode = "11111" THEN
                IF rti_counter < 6 THEN
                    rti_counter <= rti_counter + 1;
                ELSE
                    rti_counter <= 0;
                END IF;
            ELSE
                rti_counter <= 0;
            END IF;

            -- External interrupt counter
            IF int = '1' AND ext_int_active = '0' THEN
                ext_int_active  <= '1';
                ext_int_counter <= 0;
            ELSIF ext_int_active = '1' THEN
                IF ext_int_counter < 6 THEN
                    ext_int_counter <= ext_int_counter + 1;
                ELSE
                    ext_int_counter <= 0;
                    ext_int_active  <= '0';
                END IF;
            END IF;

        END IF;

        ret_counter_sig  <= ret_counter;
        popped_pc_delayed  <= popped_pc_immediate;
        popped_pc_delayed_2 <= popped_pc_delayed;
        idx_delayed_1 <= idx_popped_pc_imm;
        idx_delayed_2 <= idx_delayed_1;
        idx_delayed_3 <= idx_delayed_2;
    END PROCESS;

    -- Combinational decode
    PROCESS (opcode, int, reset, swap_counter, ret_counter_sig, rti_counter, int_idx_counter, ext_int_active, ext_int_counter)
    BEGIN
        ext_int_popped_pc   <= '0';
        ext_int_read_m1_int <= '0';
        if_id_enable        <= '1';
        if_id_flush         <= '0';
        id_ex1_flush        <= '0';
        pc_en               <= '1';
        imm_jump            <= '0';
        wb_enable           <= '0';
        jmp_cond_or_none    <= "11";
        alu_func            <= "000";
        ccr_enable          <= '0';
        alu_src_sel         <= "00";
        swap_or_1op         <= '0';
        wb_address_sel      <= '0';
        is_push             <= '0';
        sp_write_enable     <= '0';
        mem_read_write_enable <= "00";
        mem_addr_sel        <= "10";
        mem_write_sel       <= "00";
        alu_mem_wb_sel      <= '0';
        output_sel          <= "11";
        popped_pc_immediate <= '0';
        swap_out            <= '0';
        idx_popped_pc_imm   <= '0';
        alu_or_mem          <= '0';

        IF ext_int_active = '1' THEN
            -- EXTERNAL INTERRUPT - 7 cycles
            pc_en        <= '0';
            if_id_enable <= '0';

            IF ext_int_counter = 0 THEN
                mem_read_write_enable <= "01";
                mem_addr_sel  <= "00";
                mem_write_sel <= "10";
                is_push       <= '1';
                sp_write_enable <= '1';

            ELSIF ext_int_counter = 1 THEN
                mem_read_write_enable <= "10";
                mem_addr_sel  <= "10";
                ext_int_read_m1_int <= '1';
                alu_mem_wb_sel <= '0';
                output_sel    <= "01";

            ELSIF ext_int_counter = 2 OR ext_int_counter = 3 OR ext_int_counter = 4 THEN
                mem_read_write_enable <= "00";
                alu_mem_wb_sel <= '0';
                output_sel    <= "01";

            ELSIF ext_int_counter = 5 THEN
                mem_read_write_enable <= "00";
                alu_mem_wb_sel        <= '0';
                output_sel            <= "01";
                ext_int_popped_pc     <= '1';
                pc_en                 <= '1';

            ELSE
                pc_en        <= '1';
                if_id_enable <= '1';
            END IF;

        ELSE
            CASE opcode IS

                WHEN "00000" => NULL; -- NOP

                WHEN "00001" => -- HLT
                    if_id_enable <= '0';
                    pc_en        <= '0';

                WHEN "00010" => -- SETC
                    alu_func   <= "010";
                    ccr_enable <= '1';

                WHEN "00011" => -- NOT Rdst
                    swap_or_1op  <= '1';
                    alu_func     <= "011";
                    wb_enable    <= '1';
                    ccr_enable   <= '1';
                    alu_mem_wb_sel <= '1';

                WHEN "00100" => -- INC Rdst
                    swap_or_1op  <= '1';
                    alu_func     <= "100";
                    wb_enable    <= '1';
                    ccr_enable   <= '1';
                    alu_mem_wb_sel <= '1';

                WHEN "00101" => -- OUT Rsrc
                    swap_or_1op    <= '0';
                    alu_mem_wb_sel <= '1';
                    output_sel     <= "10";

                WHEN "00110" => -- IN Rdst
                    swap_or_1op  <= '1';
                    alu_func     <= "001";
                    alu_src_sel  <= "10";
                    wb_enable    <= '1';
                    ccr_enable   <= '1';
                    alu_mem_wb_sel <= '1';

                WHEN "01000" => -- MOV
                    wb_enable      <= '1';
                    alu_mem_wb_sel <= '1';

                WHEN "01001" => -- SWAP Rdst, Rsrc
                    IF swap_counter = '0' THEN
                        swap_or_1op  <= '1';
                        wb_address_sel <= '1';
                        if_id_enable <= '0';
                        pc_en        <= '0';
                    ELSE
                        swap_out     <= '1';
                        swap_or_1op  <= '0';
                        wb_address_sel <= '0';
                    END IF;
                    wb_enable      <= '1';
                    alu_mem_wb_sel <= '1';

                WHEN "01010" => -- ADD
                    alu_func <= "101";
                    wb_enable    <= '1';
                    ccr_enable   <= '1';
                    alu_mem_wb_sel <= '1';

                WHEN "01011" => -- SUB
                    alu_func <= "110";
                    wb_enable    <= '1';
                    ccr_enable   <= '1';
                    alu_mem_wb_sel <= '1';

                WHEN "01100" => -- AND
                    alu_func <= "111";
                    wb_enable    <= '1';
                    ccr_enable   <= '1';
                    alu_mem_wb_sel <= '1';

                ---- MEMORY
                WHEN "10000" => -- PUSH
                    alu_func     <= "000";
                    mem_read_write_enable <= "01";
                    mem_addr_sel <= "00";
                    is_push      <= '1';
                    sp_write_enable <= '1';

                WHEN "10001" => -- POP Rdst
                    wb_enable  <= '1';
                    mem_read_write_enable <= "10";
                    mem_addr_sel <= "01";
                    sp_write_enable <= '1';

                WHEN "10100" => -- LDM Rdst, Imm
                    wb_enable    <= '1';
                    alu_func     <= "001";
                    alu_src_sel  <= "01";
                    alu_mem_wb_sel <= '1';

                WHEN "10101" => -- LDD Rdst, offset(Rsrc)
                    wb_enable    <= '1';
                    alu_func     <= "101";
                    alu_src_sel  <= "01";
                    mem_read_write_enable <= "10";
                    mem_addr_sel <= "10";

                WHEN "10110" => -- STD Rsrc1, offset(Rsrc2)
                    alu_func    <= "101";
                    alu_src_sel <= "01";
                    mem_read_write_enable <= "01";
                    mem_addr_sel <= "10";

                WHEN "10111" => -- IADD Rdst, Rsrc, Imm
                    wb_enable    <= '1';
                    alu_func     <= "101";
                    ccr_enable   <= '1';
                    alu_src_sel  <= "01";
                    alu_mem_wb_sel <= '1';

                -- Branches resolved in EX2:
                -- On a taken branch, flush IF/ID AND ID/EX1
                -- (two stages entered after the branch instruction)
                -- The flush signals driven by the fetch/CU when
                -- jump_taken comes back from EX2. For the CU the signals
                -- if_id_flush and id_ex1_flush are driven together when
                -- jmp_cond_result/imm_jump fires; for conditional branches
                -- the flush is issued one cycle later (in EX2)

                WHEN "11000" => -- JZ
                    jmp_cond_or_none <= "00";
                    ccr_enable       <= '1';

                WHEN "11001" => -- JN
                    jmp_cond_or_none <= "01";
                    ccr_enable       <= '1';

                WHEN "11010" => -- JC
                    jmp_cond_or_none <= "10";
                    ccr_enable       <= '1';

                WHEN "11011" => -- JMP (unconditional)
                    imm_jump     <= '1';
                    if_id_flush  <= '1';
                    id_ex1_flush <= '1';

                WHEN "11100" => -- CALL
                    imm_jump     <= '1';
                    if_id_flush  <= '1';
                    id_ex1_flush <= '1';
                    mem_write_sel <= "10";
                    mem_read_write_enable <= "01";
                    mem_addr_sel  <= "00";
                    is_push       <= '1';
                    sp_write_enable <= '1';

                ---- RET
                WHEN "11101" =>
                    pc_en        <= '0';
                    if_id_enable <= '0';
                    popped_pc_immediate <= '0';

                    IF ret_counter_sig = 0 THEN
                        mem_read_write_enable <= "10";
                        mem_addr_sel  <= "01";
                        sp_write_enable <= '1';
                        alu_mem_wb_sel <= '0';
                        output_sel    <= "01";

                    ELSIF ret_counter_sig = 1 OR ret_counter_sig = 2 THEN
                        alu_mem_wb_sel <= '0';
                        output_sel     <= "01";

                    ELSIF ret_counter_sig = 3 THEN
                        pc_en               <= '1';
                        if_id_enable        <= '1';
                        popped_pc_immediate <= '1';
                    END IF;

                ---- INT
                WHEN "11110" =>
                    pc_en        <= '0';
                    if_id_enable <= '0';
                    idx_popped_pc_imm <= '0';

                    IF int_idx_counter = 0 THEN
                        mem_read_write_enable <= "01";
                        mem_addr_sel  <= "00";
                        mem_write_sel <= "10";
                        is_push       <= '1';
                        sp_write_enable <= '1';

                    ELSIF int_idx_counter = 1 THEN
                        mem_read_write_enable <= "01";
                        mem_addr_sel  <= "00";
                        mem_write_sel <= "01";
                        is_push       <= '1';
                        sp_write_enable <= '1';

                    ELSIF int_idx_counter = 2 THEN
                        mem_read_write_enable <= "10";
                        mem_addr_sel  <= "11";
                        alu_mem_wb_sel <= '0';
                        output_sel    <= "01";

                    ELSIF int_idx_counter = 3 OR int_idx_counter = 4 OR
                          int_idx_counter = 5 THEN
                        alu_mem_wb_sel <= '0';
                        output_sel     <= "01";

                    ELSIF int_idx_counter = 6 THEN
                        alu_mem_wb_sel    <= '0';
                        output_sel        <= "01";
                        idx_popped_pc_imm <= '1';
                        pc_en             <= '1';

                    ELSE
                        pc_en        <= '1';
                        if_id_enable <= '1';
                    END IF;

                ---- RTI
                WHEN "11111" =>
                    pc_en        <= '0';
                    if_id_enable <= '0';
                    popped_pc_immediate <= '0';

                    IF rti_counter = 0 THEN
                        ccr_enable    <= '1';
                        mem_read_write_enable <= "10";
                        mem_addr_sel  <= "01";
                        sp_write_enable <= '1';
                        alu_mem_wb_sel <= '0';
                        output_sel    <= "00";

                    ELSIF rti_counter = 1 THEN
                        mem_read_write_enable <= "10";
                        mem_addr_sel  <= "01";
                        sp_write_enable <= '1';
                        alu_mem_wb_sel <= '0';
                        output_sel    <= "01";

                    ELSIF rti_counter = 2 OR rti_counter = 3 OR
                          rti_counter = 4 THEN
                        alu_mem_wb_sel <= '0';
                        output_sel     <= "01";

                    ELSIF rti_counter = 5 THEN
                        alu_mem_wb_sel      <= '0';
                        output_sel          <= "01";
                        popped_pc_immediate <= '1';
                        pc_en               <= '1';

                    ELSE
                        pc_en        <= '1';
                        if_id_enable <= '1';
                    END IF;

                WHEN OTHERS => NULL;
            END CASE;
        END IF;
    END PROCESS;

    popped_pc <= popped_pc_immediate OR popped_pc_delayed OR popped_pc_delayed_2 OR ext_int_popped_pc;
    idx_popped_pc_immediate_out <= idx_popped_pc_imm OR ext_int_popped_pc;
    ext_int_read_m1             <= ext_int_read_m1_int;

END ARCHITECTURE behavioral;
