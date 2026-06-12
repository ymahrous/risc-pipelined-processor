-- ============================================================
-- between Execute-1 (ALU) and Execute-2 (branch resolve + LDD/STD address)
--
-- Connect everything the EX2 stage needs:
--   ALU result (for branch condition evaluation and MEM address)
--   read_data_2 (for STD write-data forwarding path)
--   CCR from EX1 (used by branch/jump detection in EX2)
--   All control signals that continue
--   Forwarding unit reads: ex1_ex2_wb_addr/enable/mem_read
-- ============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ex1_ex2_register IS
    GENERIC (
        WIDTH : INTEGER := 32
    );
    PORT (
        clk    : IN STD_LOGIC;
        reset  : IN STD_LOGIC;
        flush  : IN STD_LOGIC; -- NOP bubble (load-use hazard)
        stall  : IN STD_LOGIC; -- freeze register content

        ---- EX1
        alu_result_in   : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        read_data_2_in  : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        ccr_in          : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        next_pc_in      : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        wb_address_in   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        index_in        : IN STD_LOGIC;

        ---- control signals
        jump_cond_or_none_in      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_write_sel_in          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        output_sel_in             : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_in            : IN STD_LOGIC;
        mem_read_write_enable_in  : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel_in        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push_in                : IN STD_LOGIC;
        sp_write_enable_in        : IN STD_LOGIC;
        wb_enable_in              : IN STD_LOGIC;
        swap_in                   : IN STD_LOGIC;

        ---- outputs
        alu_result_out  : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        read_data_2_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        ccr_out         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        next_pc_out     : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        wb_address_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        index_out       : OUT STD_LOGIC;

        jump_cond_or_none_out     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_write_sel_out         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        output_sel_out            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_out           : OUT STD_LOGIC;
        mem_read_write_enable_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel_out       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push_out               : OUT STD_LOGIC;
        sp_write_enable_out       : OUT STD_LOGIC;
        wb_enable_out             : OUT STD_LOGIC;
        swap_out                  : OUT STD_LOGIC
    );
END ENTITY ex1_ex2_register;

ARCHITECTURE behavioral OF ex1_ex2_register IS
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF reset = '0' THEN
            alu_result_out            <= (OTHERS => '0');
            read_data_2_out           <= (OTHERS => '0');
            ccr_out                   <= (OTHERS => '0');
            next_pc_out               <= (OTHERS => '0');
            wb_address_out            <= (OTHERS => '0');
            index_out                 <= '0';
            jump_cond_or_none_out     <= "11";
            mem_write_sel_out         <= "00";
            output_sel_out            <= "11";
            alu_mem_sel_out           <= '0';
            mem_read_write_enable_out <= "00";
            mem_address_sel_out       <= "10";
            is_push_out               <= '0';
            sp_write_enable_out       <= '0';
            wb_enable_out             <= '0';
            swap_out                  <= '0';

        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                -- NOP bubble
                alu_result_out            <= (OTHERS => '0');
                read_data_2_out           <= (OTHERS => '0');
                ccr_out                   <= (OTHERS => '0');
                next_pc_out               <= (OTHERS => '0');
                wb_address_out            <= (OTHERS => '0');
                index_out                 <= '0';
                jump_cond_or_none_out     <= "11";
                mem_write_sel_out         <= "00";
                output_sel_out            <= "11";
                alu_mem_sel_out           <= '0';
                mem_read_write_enable_out <= "00";
                mem_address_sel_out       <= "10";
                is_push_out               <= '0';
                sp_write_enable_out       <= '0';
                wb_enable_out             <= '0';
                swap_out                  <= '0';

            ELSIF stall = '0' THEN
                alu_result_out            <= alu_result_in;
                read_data_2_out           <= read_data_2_in;
                ccr_out                   <= ccr_in;
                next_pc_out               <= next_pc_in;
                wb_address_out            <= wb_address_in;
                index_out                 <= index_in;
                jump_cond_or_none_out     <= jump_cond_or_none_in;
                mem_write_sel_out         <= mem_write_sel_in;
                output_sel_out            <= output_sel_in;
                alu_mem_sel_out           <= alu_mem_sel_in;
                mem_read_write_enable_out <= mem_read_write_enable_in;
                mem_address_sel_out       <= mem_address_sel_in;
                is_push_out               <= is_push_in;
                sp_write_enable_out       <= sp_write_enable_in;
                wb_enable_out             <= wb_enable_in;
                swap_out                  <= swap_in;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;