LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY if_id_register IS
  GENERIC (
    WIDTH : INTEGER := 32
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    stall : IN STD_LOGIC;
    flush : IN STD_LOGIC;
    in_port_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);

    -- from IF stage
    next_pc_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    instruction_in : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    imm_follows : IN STD_LOGIC;

    -- to ID stage
    next_pc_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    instruction_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    in_port_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    imm_follows_out : OUT STD_LOGIC
  );
END if_id_register;

ARCHITECTURE behavior OF if_id_register IS
  CONSTANT NOP_INSTRUCTION : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

  SIGNAL next_pc_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL instruction_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL in_port_reg : STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
  SIGNAL imm_follows_reg : STD_LOGIC;

BEGIN
  PROCESS (clk, reset) BEGIN
    IF reset = '0' THEN
      next_pc_reg <= (OTHERS => '0');
      instruction_reg <= NOP_INSTRUCTION;
      in_port_reg <= (OTHERS => '0');
      imm_follows_reg <= '0';
    ELSIF rising_edge(clk) THEN
      IF stall = '1' THEN
        next_pc_reg <= next_pc_reg;
        instruction_reg <= instruction_reg;
        in_port_reg <= in_port_reg;
        imm_follows_reg <= imm_follows_reg;
      ELSIF flush = '1' THEN
        next_pc_reg <= next_pc_in;
        instruction_reg <= NOP_INSTRUCTION;
        in_port_reg <= (OTHERS => '0');
        imm_follows_reg <= '0';
      ELSE
        next_pc_reg <= next_pc_in;
        instruction_reg <= instruction_in;
        in_port_reg <= in_port_in;
        imm_follows_reg <= imm_follows;
      END IF;
    END IF;
  END PROCESS;
  next_pc_out <= next_pc_reg;
  instruction_out <= instruction_reg;
  in_port_out <= in_port_reg;
  imm_follows_out <= imm_follows_reg;
END ARCHITECTURE behavior;