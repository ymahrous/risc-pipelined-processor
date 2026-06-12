LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY id_ex1_register IS
  GENERIC (
    WIDTH : INTEGER := 32
  );
  PORT (
    clk   : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    stall : IN STD_LOGIC;
    flush : IN STD_LOGIC;   -- flush on branch taken
    in_port_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);

    -- Control signals
    alu_func_sel : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    alu_src_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    swap_in : IN STD_LOGIC;

    jump_cond_or_none : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    mem_write_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    output_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    alu_mem_sel : IN STD_LOGIC;
    mem_read_write_enable : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

    mem_address_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    is_push : IN STD_LOGIC;
    sp_write_enable : IN STD_LOGIC;

    wb_enable : IN STD_LOGIC;

    ccr_enable_in : IN STD_LOGIC;

    -- from IF/ID stage
    next_pc_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);

    -- from ID stage
    read_data_1_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    read_data_2_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    immediate_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    index_in : IN STD_LOGIC;
    wb_address_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- forwarding signals
    read_address_1_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    read_address_2_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- to EX1 stage
    read_data_1_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    read_data_2_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    immediate_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    index_out : OUT STD_LOGIC;
    next_pc_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    wb_address_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- outputs control signals
    alu_func_sel_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    alu_src_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    jump_cond_or_none_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

    mem_write_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    output_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    alu_mem_sel_out : OUT STD_LOGIC;
    mem_read_write_enable_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    swap_out : OUT STD_LOGIC;

    mem_address_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    is_push_out : OUT STD_LOGIC;
    sp_write_enable_out : OUT STD_LOGIC;
    wb_enable_out : OUT STD_LOGIC;
    in_port_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);

    ccr_enable_out : OUT STD_LOGIC;

    -- forwarding unit
    read_address_1_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    read_address_2_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END id_ex1_register;

ARCHITECTURE behavioral OF id_ex1_register IS
  SIGNAL next_pc_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL read_data_1_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL read_data_2_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL immediate_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL index_reg : STD_LOGIC;
  SIGNAL wb_address_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL mem_write_sel_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL output_sel_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL alu_mem_sel_reg : STD_LOGIC;
  SIGNAL mem_read_write_enable_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL mem_address_sel_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL is_push_reg : STD_LOGIC;
  SIGNAL sp_write_enable_reg : STD_LOGIC;
  SIGNAL wb_enable_reg : STD_LOGIC;
  SIGNAL read_address_1_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL read_address_2_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL alu_func_sel_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL alu_src_sel_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL jump_cond_or_none_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL ccr_enable_reg : STD_LOGIC;
  SIGNAL swap_reg : STD_LOGIC;
  SIGNAL in_port_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
BEGIN
  PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      next_pc_reg <= (OTHERS => '0');
      read_data_1_reg <= (OTHERS => '0');
      read_data_2_reg <= (OTHERS => '0');
      immediate_reg <= (OTHERS => '0');
      index_reg <= '0';
      wb_address_reg <= (OTHERS => '0');
      mem_write_sel_reg <= (OTHERS => '0');
      output_sel_reg <= "11";
      alu_mem_sel_reg <= '0';
      mem_read_write_enable_reg <= (OTHERS => '0');
      mem_address_sel_reg <= (OTHERS => '0');
      is_push_reg <= '0';
      sp_write_enable_reg <= '0';
      wb_enable_reg <= '0';
      read_address_1_reg <= (OTHERS => '0');
      read_address_2_reg <= (OTHERS => '0');
      alu_func_sel_reg <= (OTHERS => '0');
      alu_src_sel_reg <= (OTHERS => '0');
      jump_cond_or_none_reg <= (OTHERS => '0');
      ccr_enable_reg <= '0';
      swap_reg <= '0';
      in_port_reg <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF flush = '1' THEN
        -- NOP bubble
        next_pc_reg               <= (OTHERS => '0');
        read_data_1_reg           <= (OTHERS => '0');
        read_data_2_reg           <= (OTHERS => '0');
        immediate_reg             <= (OTHERS => '0');
        index_reg                 <= '0';
        wb_address_reg            <= (OTHERS => '0');
        mem_write_sel_reg         <= (OTHERS => '0');
        output_sel_reg            <= "11";
        alu_mem_sel_reg           <= '0';
        mem_read_write_enable_reg <= (OTHERS => '0');
        mem_address_sel_reg       <= (OTHERS => '0');
        is_push_reg               <= '0';
        sp_write_enable_reg       <= '0';
        wb_enable_reg             <= '0';
        read_address_1_reg        <= (OTHERS => '0');
        read_address_2_reg        <= (OTHERS => '0');
        alu_func_sel_reg          <= (OTHERS => '0');
        alu_src_sel_reg           <= (OTHERS => '0');
        jump_cond_or_none_reg     <= "11";
        ccr_enable_reg            <= '0';
        swap_reg                  <= '0';
        in_port_reg               <= (OTHERS => '0');
      ELSIF stall = '0' THEN
        next_pc_reg <= next_pc_in;
        read_data_1_reg <= read_data_1_in;
        read_data_2_reg <= read_data_2_in;
        immediate_reg <= immediate_in;
        index_reg <= index_in;
        wb_address_reg <= wb_address_in;
        mem_write_sel_reg <= mem_write_sel;
        output_sel_reg <= output_sel;
        alu_mem_sel_reg <= alu_mem_sel;
        mem_read_write_enable_reg <= mem_read_write_enable;
        mem_address_sel_reg <= mem_address_sel;
        is_push_reg <= is_push;
        sp_write_enable_reg <= sp_write_enable;
        wb_enable_reg <= wb_enable;
        read_address_1_reg <= read_address_1_in;
        read_address_2_reg <= read_address_2_in;
        alu_func_sel_reg <= alu_func_sel;
        alu_src_sel_reg <= alu_src_sel;
        jump_cond_or_none_reg <= jump_cond_or_none;
        ccr_enable_reg <= ccr_enable_in;
        swap_reg <= swap_in;
        in_port_reg <= in_port_in;
      END IF;
    END IF;
  END PROCESS;

  read_data_1_out <= read_data_1_reg;
  read_data_2_out <= read_data_2_reg;
  immediate_out <= immediate_reg;
  index_out <= index_reg;
  next_pc_out <= next_pc_reg;
  wb_address_out <= wb_address_reg;

  ccr_enable_out <= ccr_enable_reg;

  alu_func_sel_out <= alu_func_sel_reg;
  alu_src_sel_out <= alu_src_sel_reg;
  jump_cond_or_none_out <= jump_cond_or_none_reg;
  swap_out <= swap_reg;
  mem_write_sel_out <= mem_write_sel_reg;
  output_sel_out <= output_sel_reg;
  alu_mem_sel_out <= alu_mem_sel_reg;
  mem_read_write_enable_out <= mem_read_write_enable_reg;

  mem_address_sel_out <= mem_address_sel_reg;
  is_push_out <= is_push_reg;
  sp_write_enable_out <= sp_write_enable_reg;
  wb_enable_out <= wb_enable_reg;

  read_address_1_out <= read_address_1_reg;
  read_address_2_out <= read_address_2_reg;
  in_port_out <= in_port_reg;

END behavioral;