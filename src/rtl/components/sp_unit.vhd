LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY sp_unit IS
  GENERIC (
    ADDR_WIDTH : INTEGER := 32
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    -- Control signals
    is_push : IN STD_LOGIC;
    sp_write_enable : IN STD_LOGIC;

    sp_out : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    sp_plus_one_out : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0)
  );
END sp_unit;

ARCHITECTURE behavioral OF sp_unit IS
  COMPONENT mux_2to1
    GENERIC (
      WIDTH : INTEGER := 32
    );
    PORT (
      input_0 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      input_1 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      sel : IN STD_LOGIC;
      output : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0)
    );
  END COMPONENT;

  SIGNAL sp_plus_one : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL sp_minus_one : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL reset_value : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL sp_reg : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL add_sub_result : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);

BEGIN
  sp_plus_one <= STD_LOGIC_VECTOR(unsigned(sp_reg) + 1);
  sp_minus_one <= STD_LOGIC_VECTOR(unsigned(sp_reg) - 1);

  reset_value <= x"00000FFF";

  add_sub_mux : mux_2to1
  GENERIC MAP(
    WIDTH => ADDR_WIDTH
  )
  PORT MAP(
    input_0 => sp_plus_one, -- pop
    input_1 => sp_minus_one, -- push 
    sel => is_push,
    output => add_sub_result
  );

  PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      sp_reg <= reset_value;
    ELSIF falling_edge(clk) THEN
      IF sp_write_enable = '1' THEN
        sp_reg <= add_sub_result;
      END IF;
    END IF;
  END PROCESS;

  sp_out <= sp_reg;
  sp_plus_one_out <= sp_plus_one;
END behavioral;