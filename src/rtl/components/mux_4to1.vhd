library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY mux_4to1 IS
    GENERIC (
        WIDTH : INTEGER := 32
    );
    PORT (
        input_0     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        input_1     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        input_2     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        input_3     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  
        sel         : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        output      : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
    );
END ENTITY mux_4to1;

ARCHITECTURE behavioral OF mux_4to1 IS
BEGIN
    PROCESS(sel, input_0, input_1, input_2, input_3)
    BEGIN
        CASE sel IS
            WHEN "00" =>
                output <= input_0;
            WHEN "01" =>
                output <= input_1;
            WHEN "10" =>
                output <= input_2;
            WHEN "11" =>
                output <= input_3;
            WHEN OTHERS =>
                output <= (OTHERS => '0');
        END CASE;
    END PROCESS;
END behavioral;