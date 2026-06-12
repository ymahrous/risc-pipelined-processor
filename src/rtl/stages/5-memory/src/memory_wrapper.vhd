LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY memory_wrapper IS
  GENERIC (
    DATA_WIDTH  : INTEGER := 32;
    MEMORY_SIZE : INTEGER := 4096;
    MEM_FILE    : STRING  := "./out.mem"
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    fetch_or_mem : IN STD_LOGIC; -- '0' for fetch, '1' for memory access
    fetch_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- Memory stage
    mem_address : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    mem_write_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    mem_read_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    mem_read_enable : IN STD_LOGIC;
    mem_write_enable : IN STD_LOGIC;

    read_enable_selector : IN STD_LOGIC;
    INT_extended : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    PC : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Hardware interrupt interface
    hardware_signal : IN STD_LOGIC;
    hw_address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END memory_wrapper;

ARCHITECTURE behavioral OF memory_wrapper IS
  COMPONENT memory IS
    GENERIC (
      DATA_WIDTH  : INTEGER := 32;
      MEMORY_SIZE : INTEGER := 4096;
      MEM_FILE    : STRING  := "./out.mem"
    );
    PORT (
      clk : IN STD_LOGIC;
      address : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      write_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
      read_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

      -- Control signals
      read_enable : IN STD_LOGIC;
      write_enable : IN STD_LOGIC
    );
  END COMPONENT;

  COMPONENT mux_4to1
    GENERIC (
      WIDTH : INTEGER := 32
    );
    PORT (
      input_0 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      input_1 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      input_2 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      input_3 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      output : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0)
    );
  END COMPONENT;

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

  SIGNAL selected_address : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL read_enable_internal : STD_LOGIC;
  SIGNAL write_enable_internal : STD_LOGIC;
  SIGNAL mem_read_data_internal : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL fetch_data_internal : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL hw_address_internal : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

  SIGNAL address_sel : STD_LOGIC_VECTOR(1 DOWNTO 0);

  SIGNAL read_enable_input_0 : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL read_enable_input_1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL read_enable_output : STD_LOGIC_VECTOR(0 DOWNTO 0);

  SIGNAL write_enable_input_0 : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL write_enable_input_1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL write_enable_output : STD_LOGIC_VECTOR(0 DOWNTO 0);

BEGIN
  address_sel <= "10" WHEN hardware_signal = '1' ELSE
    "01" WHEN fetch_or_mem = '1' ELSE
    "00";

  -- Address selection: fetch -> 00, memory -> 01, interrupt -> 10
  address_mux : mux_4to1
  GENERIC MAP(
    WIDTH => 32
  )
  PORT MAP(
    input_0 => PC,
    input_1 => mem_address,
    input_2 => INT_extended,
    input_3 => (OTHERS => '0'),
    sel => address_sel,
    output => selected_address
  );

  read_enable_input_0(0) <= '1'; -- Always enable read for fetch
  read_enable_input_1(0) <= mem_read_enable;

  read_enable_mux : mux_2to1
  GENERIC MAP(
    WIDTH => 1
  )
  PORT MAP(
    input_0 => read_enable_input_0,
    input_1 => read_enable_input_1,
    sel => read_enable_selector,
    output => read_enable_output
  );

  read_enable_internal <= read_enable_output(0);

  write_enable_input_0(0) <= '0'; -- Disable write for fetch
  write_enable_input_1(0) <= mem_write_enable;

  -- WE selection
  mem_write_enable_mux : mux_2to1
  GENERIC MAP(
    WIDTH => 1
  )
  PORT MAP(
    input_0 => write_enable_input_0,
    input_1 => write_enable_input_1,
    sel => fetch_or_mem,
    output => write_enable_output
  );

  write_enable_internal <= write_enable_output(0);

  mem_inst: memory
  GENERIC MAP(
    DATA_WIDTH  => DATA_WIDTH,
    MEMORY_SIZE => MEMORY_SIZE,
    MEM_FILE    => MEM_FILE
  )
  PORT MAP(
    clk => clk,
    address => selected_address,
    write_data => mem_write_data,
    read_data => mem_read_data_internal,
    read_enable => read_enable_internal,
    write_enable => write_enable_internal
  );

  -- Output selector for read data
  output_demux : demux_1to4
  GENERIC MAP(
    WIDTH => DATA_WIDTH
  )
  PORT MAP(
    input => mem_read_data_internal,
    sel => address_sel, -- 00: fetch, 01: memory, 10: hardware interrupt
    output_0 => fetch_data_internal,
    output_1 => mem_read_data,
    output_2 => hw_address_internal,
    output_3 => OPEN
  );

  fetch_data <= fetch_data_internal;
  hw_address <= hw_address_internal;

END behavioral;