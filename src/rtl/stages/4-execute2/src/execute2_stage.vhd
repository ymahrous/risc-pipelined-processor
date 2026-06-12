-- ============================================================
-- Main functions:
--   1. BRANCH RESOLUTION
--      Receives CCR from EX1/EX2 and evaluates conditional-jump conditions.
--      Drives jump_taken and flag-reset signals back to the fetch stage.
--
--   2. LDD / STD ADDRESS CALCULATION
--      The base register + offset addition was done by the ALU
--      in EX1.  The result (alu_result) is passed through
--      to the EX2/MEM register as the memory address. EX2 just acts as a buffer cycle
--      that lets the branch resolution complete before the
--      instruction enters the memory port arbitration cycle.
-- ============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY execute2_stage IS
    GENERIC (
        WIDTH : INTEGER := 32
    );
    PORT (
        ccr_in                : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- conditional-jump control from ID/EX1
        jump_cond_or_none     : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Branch resolution outputs (to fetch stage)
        jump_taken            : OUT STD_LOGIC;
        reset_ccr_z           : OUT STD_LOGIC;
        reset_ccr_n           : OUT STD_LOGIC;
        reset_ccr_c           : OUT STD_LOGIC
    );
END ENTITY execute2_stage;

ARCHITECTURE behavioral OF execute2_stage IS
    COMPONENT jump_detection_unit IS
        PORT (
            ccr_in                 : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            conditional_jump_or_not: IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            jump_cond_result       : OUT STD_LOGIC;
            reset_z                : OUT STD_LOGIC;
            reset_n                : OUT STD_LOGIC;
            reset_c                : OUT STD_LOGIC
        );
    END COMPONENT;
BEGIN
    jdu: jump_detection_unit
    PORT MAP (
        ccr_in                  => ccr_in,
        conditional_jump_or_not => jump_cond_or_none,
        jump_cond_result        => jump_taken,
        reset_z                 => reset_ccr_z,
        reset_n                 => reset_ccr_n,
        reset_c                 => reset_ccr_c
    );
END ARCHITECTURE behavioral;