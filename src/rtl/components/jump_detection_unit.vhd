LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY jump_detection_unit IS
  PORT (
    ccr_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    conditional_jump_or_not : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    jump_cond_result : OUT STD_LOGIC;
    reset_z : OUT STD_LOGIC;
    reset_n : OUT STD_LOGIC;
    reset_c : OUT STD_LOGIC
  );
END jump_detection_unit;
ARCHITECTURE behavioral OF jump_detection_unit IS
BEGIN
  PROCESS (ccr_in, conditional_jump_or_not)
  BEGIN
    reset_z <= '0';
    reset_n <= '0';
    reset_c <= '0';
    CASE conditional_jump_or_not IS
      WHEN "00" => -- Jump if zero
        jump_cond_result <= ccr_in(0);
        reset_z <= ccr_in(0);
      WHEN "01" => -- Jump if negative
        jump_cond_result <= ccr_in(1);
        reset_n <= ccr_in(1);
      WHEN "10" => -- Jump if overflow
        jump_cond_result <= ccr_in(2);
        reset_c <= ccr_in(2);
      WHEN OTHERS =>
        jump_cond_result <= '0';
    END CASE;
  END PROCESS;
END ARCHITECTURE behavioral;