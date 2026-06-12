LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY memory_stage IS
  GENERIC (
    DATA_WIDTH : INTEGER := 32;
    ADDR_WIDTH : INTEGER := 32;
    MEMORY_SIZE : INTEGER := 4096
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    -- inputs from EX2/MEM
    alu_result : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    index : IN STD_LOGIC;
    read_data_2 : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    next_pc : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    -- control signals:
    --    write data select : 00 (Rsrc2), 01 (Extended CCR), 10 (Next PR), 11 (Zero)
    mem_write_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    -- memory address select : 00 (SP), 01 (SP+1), 10 (ALU result), 11 (Index+2)
    mem_address_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- sp signals
    sp_write_enable : IN STD_LOGIC;
    is_push : IN STD_LOGIC;

    -- CCR input (for INT/RTI)
    ccr_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- memory interface
    mem_address    : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    mem_write_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    sp_out         : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0)
  );
END memory_stage;

ARCHITECTURE behavioral OF memory_stage IS
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

  COMPONENT sp_unit IS
    GENERIC (
      ADDR_WIDTH : INTEGER := 32
    );
    PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      is_push : IN STD_LOGIC;
      sp_write_enable : IN STD_LOGIC;
      sp_out : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
      sp_plus_one_out : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0)
    );
  END COMPONENT;

  -- address calculation
  SIGNAL sp_plus_one : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL index_plus_two : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL index_extended : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL ccr_extended : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL sp_value_internal   : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL mem_address_internal : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
BEGIN
  index_extended <= (ADDR_WIDTH - 1 DOWNTO 1 => '0') & index;
  index_plus_two <= STD_LOGIC_VECTOR(unsigned(index_extended) + 2);

  -- Memory address mux
  mem_address_mux : mux_4to1
  GENERIC MAP(
    WIDTH => ADDR_WIDTH
  )
  PORT MAP(
    input_0 => sp_value_internal,
    input_1 => sp_plus_one,
    input_2 => alu_result,
    input_3 => index_plus_two,
    sel => mem_address_sel,
    output => mem_address_internal
  );

  mem_address <= mem_address_internal;
  sp_out      <= sp_value_internal;

  ccr_extended <= STD_LOGIC_VECTOR((DATA_WIDTH - 1 DOWNTO 3 => '0') & ccr_in);

  -- Memory write data mux
  mem_write_data_mux : mux_4to1
  GENERIC MAP(
    WIDTH => DATA_WIDTH
  )
  PORT MAP(
    input_0 => read_data_2,
    input_1 => ccr_extended,
    input_2 => next_pc,
    input_3 => (DATA_WIDTH - 1 DOWNTO 0 => '0'),
    sel => mem_write_sel,
    output => mem_write_data
  );

  sp_unit_inst: sp_unit
  GENERIC MAP(
    ADDR_WIDTH => ADDR_WIDTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    is_push => is_push,
    sp_write_enable => sp_write_enable,
    sp_out => sp_value_internal,
    sp_plus_one_out => sp_plus_one
  );

END behavioral;