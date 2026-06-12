-- ============================================================
-- three hazards:
--
-- 1) Load-use (load at EX1/EX2 stage, consumer entering EX1)
--    stall PC, IF/ID, ID/EX1 for 1 cycle; flush EX1/EX2 (bubble)
--
-- 2) Load-use (load at EX2/MEM stage, consumer entering EX1)
--    Same action.  Handled separately to cover the 2-cycle window.
--
-- 3) One memory structural hazard (MEM read or write active)
--    stall PC and fetch; redirect memory port to MEM stage.
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY hazard_control_unit IS
    PORT (
        load_use_ex2    : IN STD_LOGIC; -- load in EX1/EX2, consumer in EX1
        load_use_mem    : IN STD_LOGIC; -- load in EX2/MEM, consumer in EX1
        mem_read_active : IN STD_LOGIC; -- EX2/MEM register has mem_read asserted
        mem_write_active: IN STD_LOGIC; -- EX2/MEM register has mem_write asserted

        stall_pc        : OUT STD_LOGIC; -- freeze PC register
        stall_if_id     : OUT STD_LOGIC; -- freeze IF/ID register
        stall_id_ex1    : OUT STD_LOGIC; -- freeze ID/EX1 register
        flush_ex1_ex2   : OUT STD_LOGIC; -- insert NOP bubble into EX1/EX2
        pc_enable       : OUT STD_LOGIC; -- PC write enable (active-high)
        fetch_or_memory : OUT STD_LOGIC  -- '1' redirect memory port to MEM stage
    );
END ENTITY hazard_control_unit;

ARCHITECTURE behavioral OF hazard_control_unit IS
BEGIN
    PROCESS (load_use_ex2, load_use_mem, mem_read_active, mem_write_active)
    BEGIN
        -- safe defaults
        stall_pc        <= '0';
        stall_if_id     <= '0';
        stall_id_ex1    <= '0';
        flush_ex1_ex2   <= '0';
        pc_enable       <= '1';
        fetch_or_memory <= '0';

        IF load_use_ex2 = '1' OR load_use_mem = '1' THEN
            -- Insert a bubble: freeze everything upwards
            stall_pc      <= '1';
            stall_if_id   <= '1';
            stall_id_ex1  <= '1';
            flush_ex1_ex2 <= '1';
            pc_enable     <= '0';

        ELSIF mem_read_active = '1' OR mem_write_active = '1' THEN
            -- Structural hazard: MEM stage needs the shared memory port
            pc_enable       <= '0';
            stall_pc        <= '1';
            stall_if_id     <= '1';
            fetch_or_memory <= '1';
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;
