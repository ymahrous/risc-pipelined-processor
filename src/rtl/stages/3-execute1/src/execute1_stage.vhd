LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY execute1_stage IS
  GENERIC (
    WIDTH : INTEGER := 32
  );
  PORT (
    clk : IN STD_LOGIC;
    -- inputs
    read_data_1 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    read_data_2 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    immiediate_value : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    ccr_write_back : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    ccr_enable : IN STD_LOGIC;

    --forwarding
    write_back_forwarding_data : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    alu_forwarding_data        : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0); -- EX2/MEM  "10"
    alu_forwarding_data_ex2    : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0); -- EX1/EX2  "11"
    fu_data_1_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    fu_data_2_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- control signals
    alu_input_selection : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    alu_op : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    ccr_write_back_en : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    -- resets - ccr
    reset_ccr_z : IN STD_LOGIC;
    reset_ccr_n : IN STD_LOGIC;
    reset_ccr_c : IN STD_LOGIC;

    -- in port for I/O operations
    in_port : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);

    -- outputs
    alu_rsrc2_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    alu_result : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    ccr_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    alu_flags_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END ENTITY execute1_stage;

ARCHITECTURE behavioral OF execute1_stage IS
  SIGNAL alu_input_a : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL alu_input_b : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL read_data_2_signal : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL ccr_current : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL ccr_alu_out : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL ccr_input : STD_LOGIC_VECTOR(2 DOWNTO 0);

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

  COMPONENT ccr_reg
    PORT (
      clk, enable, reset : IN STD_LOGIC;
      reset_z : IN STD_LOGIC;
      reset_n : IN STD_LOGIC;
      reset_c : IN STD_LOGIC;
      d : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      q : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
  END COMPONENT;

BEGIN
  ccr_input <= ccr_write_back WHEN ccr_write_back_en = '1' ELSE ccr_alu_out;

  ccr_register : ENTITY work.ccr
    PORT MAP(
      clk => clk,
      enable => ccr_enable,
      reset => reset,
      reset_z => reset_ccr_z,
      reset_n => reset_ccr_n,
      reset_c => reset_ccr_c,
      d => ccr_input,
      q => ccr_current
    );

  ccr_out <= ccr_current;
  alu_rsrc2_out <= read_data_2_signal;

  -- sel "00"=reg file  "01"=WB  "10"=EX2/MEM  "11"=EX1/EX2
  alu_input_a_mux : ENTITY work.mux_4to1
    GENERIC MAP(WIDTH => WIDTH)
    PORT MAP(
      input_0 => read_data_1,
      input_1 => write_back_forwarding_data,
      input_2 => alu_forwarding_data,
      input_3 => alu_forwarding_data_ex2,
      sel => fu_data_1_sel(1 DOWNTO 0),
      output => alu_input_a
    );

  -- sel "00"=reg file  "01"=WB  "10"=EX2/MEM  "11"=EX1/EX2
  read_data_2_mux : ENTITY work.mux_4to1
    GENERIC MAP(WIDTH => WIDTH)
    PORT MAP(
      input_0 => read_data_2,
      input_1 => write_back_forwarding_data,
      input_2 => alu_forwarding_data,
      input_3 => alu_forwarding_data_ex2,
      sel => fu_data_2_sel(1 DOWNTO 0),
      output => read_data_2_signal
    );

  alu_input_b_mux : ENTITY work.mux_4to1
    GENERIC MAP(WIDTH => WIDTH)
    PORT MAP(
      input_0 => read_data_2_signal,
      input_1 => immiediate_value,
      input_2 => in_port,
      input_3 => (OTHERS => '0'), -- Unused
      sel => alu_input_selection(1 DOWNTO 0),
      output => alu_input_b
    );

  alu_inst : ENTITY work.alu
    GENERIC MAP(WIDTH => WIDTH)
    PORT MAP(
      a => alu_input_a,
      b => alu_input_b,
      ccr => ccr_current,
      alu_op => alu_op,
      result => alu_result,
      ccr_out => ccr_alu_out
    );
  alu_flags_out <= ccr_alu_out;
END ARCHITECTURE behavioral;