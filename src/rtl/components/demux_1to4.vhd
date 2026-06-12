LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY demux_1to4 IS
  GENERIC (
    WIDTH : INTEGER := 32
  );
  PORT (
    input : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    output_0 : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    output_1 : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    output_2 : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    output_3 : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0)
  );
END demux_1to4;

ARCHITECTURE behavioral OF demux_1to4 IS
BEGIN
  PROCESS (input, sel)
  BEGIN
    output_0 <= (OTHERS => '0');
    output_1 <= (OTHERS => '0');
    output_2 <= (OTHERS => '0');
    output_3 <= (OTHERS => '0');

    CASE sel IS
      WHEN "00" =>
        output_0 <= input;
      WHEN "01" =>
        output_1 <= input;
      WHEN "10" =>
        output_2 <= input;
      WHEN "11" =>
        output_3 <= input;
      WHEN OTHERS =>
        NULL;
    END CASE;
  END PROCESS;
END behavioral;