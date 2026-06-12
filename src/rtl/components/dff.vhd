LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY dff IS
    PORT (
        d : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        clk, reset : IN STD_LOGIC;
        q : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY dff;

ARCHITECTURE behavioral OF dff IS
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF reset = '0' THEN
            q <= (OTHERS => '0');
        ELSE
            IF rising_edge(clk) THEN
                q <= d;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;