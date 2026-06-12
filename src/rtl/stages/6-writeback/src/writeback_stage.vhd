LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY writeback_stage IS
  GENERIC (
    DATA_WIDTH : INTEGER := 32
  );
  PORT (
    -- write_back_enable : IN STD_LOGIC;
    output_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    alu_mem_sel : IN STD_LOGIC;

    -- inputs
    alu_result : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    mem_read_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- output
    ccr_extended : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    popped_PC : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    write_back_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    output_port : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
  );
END writeback_stage;

ARCHITECTURE behavioral OF writeback_stage IS
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

  COMPONENT demux_1to4
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
  END COMPONENT;

  SIGNAL output_data_internal : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
BEGIN
  -- result comes from ALU or Memory
  mem_alu_mux : mux_2to1
  GENERIC MAP(
    WIDTH => DATA_WIDTH
  )
  PORT MAP(
    input_0 => mem_read_data,
    input_1 => alu_result,
    sel => alu_mem_sel,
    output => output_data_internal
  );

  output_demux : demux_1to4
  GENERIC MAP(
    WIDTH => DATA_WIDTH
  )
  PORT MAP(
    input => output_data_internal,
    sel => output_sel,
    output_0 => ccr_extended,
    output_1 => popped_PC,
    output_2 => output_port,
    output_3 => write_back_data
  );

END ARCHITECTURE behavioral;