LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY imm_detect IS
    GENERIC (
        instr_width : INTEGER := 32
    );
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        instruction : IN STD_LOGIC_VECTOR(instr_width - 1 DOWNTO 0);
        imm_follows : OUT STD_LOGIC;
        cur_is_imm : OUT STD_LOGIC
    );
END ENTITY imm_detect;

ARCHITECTURE behavioral OF imm_detect IS
    SIGNAL opcode : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL imm_follows_next : STD_LOGIC;
    SIGNAL imm_follows_int : STD_LOGIC := '0';
BEGIN

    opcode <= instruction(instr_width - 1 DOWNTO instr_width - 5);
    imm_follows <= imm_follows_int;
    cur_is_imm <= imm_follows_next;
    -- determine if immediate
    PROCESS (opcode, imm_follows_int)
    BEGIN
        IF imm_follows_int = '1' THEN
            imm_follows_next <= '0';
        ELSE
            CASE opcode IS
                WHEN "10111" => imm_follows_next <= '1'; -- IADD
                WHEN "10100" => imm_follows_next <= '1'; -- LDM
                WHEN "10101" => imm_follows_next <= '1'; -- LDD
                WHEN "10110" => imm_follows_next <= '1'; -- STD
                WHEN "11000" => imm_follows_next <= '1'; -- JZ
                WHEN "11001" => imm_follows_next <= '1'; -- JN
                WHEN "11010" => imm_follows_next <= '1'; -- JC
                WHEN "11011" => imm_follows_next <= '1'; -- JMP
                WHEN "11100" => imm_follows_next <= '1'; -- CALL
                WHEN OTHERS => imm_follows_next <= '0';
            END CASE;
        END IF;
    END PROCESS;

    PROCESS (clk, reset)
    BEGIN
        IF reset = '0' THEN
            imm_follows_int <= '0';
        ELSIF rising_edge(clk) THEN
            imm_follows_int <= imm_follows_next;
        END IF;
    END PROCESS;

END ARCHITECTURE behavioral;