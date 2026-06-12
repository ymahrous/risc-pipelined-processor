LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY mem_wb_register IS
  GENERIC (
    WIDTH : INTEGER := 32
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    stall : IN STD_LOGIC;

    -- control signals
    wb_enable_in : IN STD_LOGIC;
    output_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    alu_mem_sel : IN STD_LOGIC;

    -- from EX/MEM stage
    read_data_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    alu_result_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    wb_address_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    wb_enable_out : OUT STD_LOGIC;
    output_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    alu_mem_sel_out : OUT STD_LOGIC;

    read_data_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    alu_result_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    wb_address_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END mem_wb_register;

ARCHITECTURE behavioral OF mem_wb_register IS
  SIGNAL wb_enable_reg : STD_LOGIC;
  SIGNAL output_sel_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL alu_mem_sel_reg : STD_LOGIC;

  SIGNAL read_data_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL alu_result_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL wb_address_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
  PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      wb_enable_reg <= '0';
      output_sel_reg <= "11";
      alu_mem_sel_reg <= '0';
      read_data_reg <= (OTHERS => '0');
      alu_result_reg <= (OTHERS => '0');
      wb_address_reg <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF stall = '0' THEN
        wb_enable_reg <= wb_enable_in;
        output_sel_reg <= output_sel;
        alu_mem_sel_reg <= alu_mem_sel;
        read_data_reg <= read_data_in;
        alu_result_reg <= alu_result_in;
        wb_address_reg <= wb_address_in;
      END IF;
    END IF;
  END PROCESS;

  wb_enable_out <= wb_enable_reg;
  output_sel_out <= output_sel_reg;
  alu_mem_sel_out <= alu_mem_sel_reg;
  read_data_out <= read_data_reg;
  alu_result_out <= alu_result_reg;
  wb_address_out <= wb_address_reg;

END ARCHITECTURE behavioral;