-- ============================================================
-- forwarding_unit.vhd
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY forwarding_unit IS
    PORT (
        -- Source addresses of the instruction currently in EX1
        read_reg_1_addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_reg_2_addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- SWAP flag: disable A-forwarding from EX2/MEM during SWAP cycle 2
        swap : IN STD_LOGIC;

        -- EX1/EX2 pipeline register destination
        ex1_ex2_wb_addr   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ex1_ex2_wb_enable : IN STD_LOGIC;
        ex1_ex2_mem_read  : IN STD_LOGIC; -- 1 when instruction in EX2 is a load (LDD/POP)

        -- EX2/MEM pipeline register destination
        ex2_mem_wb_addr   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ex2_mem_wb_enable : IN STD_LOGIC;
        ex2_mem_mem_read  : IN STD_LOGIC; -- 1 when instruction in MEM is a load

        -- MEM/WB pipeline register destination
        mem_wb_addr   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_wb_enable : IN STD_LOGIC;

        -- Forwarding mux selects for operands A and B entering the ALU in EX1
        -- "00" no forward (register file)
        -- "01" forward from WB  (MEM/WB.result)
        -- "10" forward from MEM (EX2/MEM.alu_result)
        -- "11" forward from EX2 (EX1/EX2.alu_result)   ← NEW
        forward_a : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        forward_b : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Hazard stall outputs (one per distance)
        -- load_use_ex2 : load is in EX2/MEM, consumer is entering EX1
        --                1 stall cycle needed (can forward after stall)
        -- load_use_mem : load is in MEM/WB,  consumer is entering EX1
        --                should not occur if load_use_ex2 was honoured,
        --                  but guard against back-to-back load-use
        load_use_ex2 : OUT STD_LOGIC;
        load_use_mem : OUT STD_LOGIC
    );
END ENTITY forwarding_unit;

ARCHITECTURE behavioral OF forwarding_unit IS
BEGIN
    PROCESS (
        read_reg_1_addr, read_reg_2_addr, swap,
        ex1_ex2_wb_addr, ex1_ex2_wb_enable, ex1_ex2_mem_read,
        ex2_mem_wb_addr, ex2_mem_wb_enable, ex2_mem_mem_read,
        mem_wb_addr, mem_wb_enable
    )
    BEGIN
        forward_a    <= "00";
        forward_b    <= "00";
        load_use_ex2 <= '0';
        load_use_mem <= '0';

        -- ============================================================
        -- OPERAND A  (read_reg_1_addr)
        -- Priority: EX2 > MEM > WB  (closest stage wins)
        -- ============================================================
        IF (ex1_ex2_wb_enable = '1') AND
           (ex1_ex2_wb_addr = read_reg_1_addr) AND
           (swap = '0')
        THEN
            forward_a <= "11"; -- EX1/EX2 path (NEW)

        ELSIF (ex2_mem_wb_enable = '1') AND
              (ex2_mem_wb_addr = read_reg_1_addr) AND
              (swap = '0')
        THEN
            forward_a <= "10"; -- EX2/MEM path

        ELSIF (mem_wb_enable = '1') AND
              (mem_wb_addr = read_reg_1_addr)
        THEN
            forward_a <= "01"; -- MEM/WB  path
        END IF;

        -- ============================================================
        -- OPERAND B  (read_reg_2_addr)
        -- ============================================================
        IF (ex1_ex2_wb_enable = '1') AND
           (ex1_ex2_wb_addr = read_reg_2_addr)
        THEN
            forward_b <= "11"; -- EX1/EX2 path (NEW)

        ELSIF (ex2_mem_wb_enable = '1') AND
              (ex2_mem_wb_addr = read_reg_2_addr)
        THEN
            forward_b <= "10"; -- EX2/MEM path

        ELSIF (mem_wb_enable = '1') AND
              (mem_wb_addr = read_reg_2_addr)
        THEN
            forward_b <= "01"; -- MEM/WB  path
        END IF;

        -- ============================================================
        -- LOAD-USE HAZARD DETECTION
        --
        -- Case 1: load in EX1/EX2 (completed EX1, heading to EX2)
        --         consumer is about to enter EX1.
        --         Result not yet computed stall 1 cycle.
        --         After stall, load will be in EX2/MEM and forward_a/b
        --         will select "10" on the retry cycle.
        -- ============================================================
        IF (ex1_ex2_wb_enable = '1') AND
           (ex1_ex2_mem_read = '1') AND
           ((ex1_ex2_wb_addr = read_reg_1_addr) OR
            (ex1_ex2_wb_addr = read_reg_2_addr))
        THEN
            load_use_ex2 <= '1';
        END IF;

        -- Case 2: load in EX2/MEM (at memory stage)
        --         about to enter EX1.
        --         Memory result not ready until end of MEM, stall 1 more.
        IF (ex2_mem_wb_enable = '1') AND
           (ex2_mem_mem_read = '1') AND
           ((ex2_mem_wb_addr = read_reg_1_addr) OR
            (ex2_mem_wb_addr = read_reg_2_addr))
        THEN
            load_use_mem <= '1';
        END IF;

    END PROCESS;
END ARCHITECTURE behavioral;
