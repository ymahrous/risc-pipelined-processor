LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pc IS
    GENERIC (
        width : INTEGER := 32
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        en : IN STD_LOGIC;
        d : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        q : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)
    );
END ENTITY pc;

ARCHITECTURE behavioral OF pc IS
    SIGNAL pc_reg : STD_LOGIC_VECTOR(width - 1 DOWNTO 0) := (OTHERS => '0');
BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rising_edge(clk) THEN
            IF en = '1' THEN
                pc_reg <= d;
            END IF;
        END IF;
    END PROCESS;

    q <= pc_reg;

END ARCHITECTURE behavioral;