LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ccr IS
  PORT (
    clk, enable, reset : IN STD_LOGIC;
    reset_z : IN STD_LOGIC;
    reset_n : IN STD_LOGIC;
    reset_c : IN STD_LOGIC;
    d : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    q : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );

END ccr;

ARCHITECTURE behavioral OF ccr IS
  SIGNAL ccr_reg : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
BEGIN
  PROCESS (clk, enable, reset, d)
  BEGIN
    IF (reset = '0') THEN
      ccr_reg <= (OTHERS => '0');
    ELSIF (rising_edge(clk) AND enable = '1') THEN
      ccr_reg <= d;
      IF (reset_z = '1') THEN
        ccr_reg(0) <= '0';
      ELSIF (reset_n = '1') THEN
        ccr_reg(1) <= '0';
      ELSIF (reset_c = '1') THEN
        ccr_reg(2) <= '0';
      END IF;
    END IF;
  END PROCESS;
  q <= ccr_reg;
END behavioral;