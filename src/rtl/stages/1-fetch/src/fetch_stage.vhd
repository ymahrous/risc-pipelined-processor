LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY fetch_stage IS
    GENERIC (
        width : INTEGER := 32
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        pc_en_in : IN STD_LOGIC;

        popped_pc_cs : IN STD_LOGIC;
        hw_cs : IN STD_LOGIC;
        imm_jump_cs : IN STD_LOGIC;
        jump_cond_cs : IN STD_LOGIC;

        -- inputs
        popped_pc : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        hw_pc : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        imm_jump : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);

        -- outputs
        next_pc : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        pc_out : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)
    );
END ENTITY fetch_stage;

ARCHITECTURE behavioral OF fetch_stage IS

    COMPONENT pc IS
        GENERIC (
            width : INTEGER := 32
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            en : IN STD_LOGIC;
            d : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
            q : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT mux_4to1 IS
        GENERIC (
            width : INTEGER := 32
        );
        PORT (
            input_0 : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
            input_1 : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
            input_2 : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
            input_3 : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
            sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            output : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT imm_detect IS
        GENERIC (
            instr_width : INTEGER := 32
        );
        PORT (
            instruction : IN STD_LOGIC_VECTOR(instr_width - 1 DOWNTO 0);
            imm_follows : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL pc_q : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL pc_d : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL pc_plus_1 : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL pc_plus_2 : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL pc_sel : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN
    pc_plus_1 <= STD_LOGIC_VECTOR(UNSIGNED(pc_q) + 1);
    pc_plus_2 <= STD_LOGIC_VECTOR(UNSIGNED(pc_q) + 2);

    pc_sel(1) <= popped_pc_cs OR hw_cs;
    pc_sel(0) <= hw_cs OR imm_jump_cs OR jump_cond_cs;

    PC_MUX : mux_4to1
    GENERIC MAP(width => width)
    PORT MAP(
        input_0 => pc_plus_1,
        input_1 => imm_jump,
        input_2 => popped_pc,
        input_3 => hw_pc,
        sel => pc_sel,
        output => pc_d
    );

    next_pc <= pc_plus_2;

    PC_REG : pc
    GENERIC MAP(width => width)
    PORT MAP(
        clk => clk,
        rst => rst,
        en => pc_en_in,
        d => pc_d,
        q => pc_q
    );

    pc_out <= pc_q;

END ARCHITECTURE behavioral;