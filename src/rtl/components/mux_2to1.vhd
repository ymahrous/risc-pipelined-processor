library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY mux_2to1 IS
  GENERIC (
    WIDTH : INTEGER := 32
  );
  PORT (
    input_0     : IN  STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    input_1     : IN  STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    sel         : IN  STD_LOGIC;
    output      : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0)
  );
END mux_2to1;

ARCHITECTURE behavioral OF mux_2to1 IS
BEGIN 
  PROCESS(sel, input_0, input_1)
  BEGIN
    CASE sel IS
      WHEN '0' =>
        output <= input_0;
      WHEN '1' =>
        output <= input_1;
      WHEN OTHERS =>
        output <= (OTHERS => '0');
    END CASE;
  END PROCESS;
END behavioral;
  