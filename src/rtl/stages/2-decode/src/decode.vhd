LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY decode IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        sw_c_1_op : IN STD_LOGIC;
        wb_addr_sel : IN STD_LOGIC;

        Rsrc1, Rsrc2, Rdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        write_reg : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        write_enable : IN STD_LOGIC;

        wb_address_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_address1_o, read_address2_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

        read_data1, read_data2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        r0, r1, r2, r3, r4, r5, r6, r7 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY decode;

ARCHITECTURE behavior OF decode IS

    TYPE reg_file_type IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL reg_file : reg_file_type := (OTHERS => (OTHERS => '0'));
    COMPONENT REGISTERS
        PORT (
            write_address : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            write_enable, clk, reset : IN STD_LOGIC;
            read_address_1, read_address_2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            read_data_1, read_data_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            r0, r1, r2, r3, r4, r5, r6, r7 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT mux_2to1
        GENERIC (
            WIDTH: INTEGER := 3
        );
        PORT (
            input_0 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
            input_1 : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
            sel : IN STD_LOGIC;
            output : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL read_address_1_final : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
    rf_inst: REGISTERS
    PORT MAP(
        write_address => write_reg,
        write_data => write_data,
        write_enable => write_enable,
        clk => clk,
        reset => reset,
        read_address_1 => read_address_1_final,
        read_address_2 => Rsrc2,
        read_data_1 => read_data1,
        read_data_2 => read_data2,
        r0 => r0,
        r1 => r1,
        r2 => r2,
        r3 => r3,
        r4 => r4,
        r5 => r5,
        r6 => r6,
        r7 => r7
    );

    -- outputs
    mux_wb_address_o : mux_2to1
    GENERIC MAP(
        WIDTH => 3
    )
    PORT MAP(
        input_0 => Rdst,
        input_1 => Rsrc1,
        sel => wb_addr_sel,
        output => wb_address_o
    );

    mux_read_address_1_o : mux_2to1
    GENERIC MAP(
        WIDTH => 3
    )
    PORT MAP(
        input_0 => Rsrc1,
        input_1 => Rdst,
        sel => sw_c_1_op,
        output => read_address_1_final
    );

    read_address1_o <= read_address_1_final;
    read_address2_o <= Rsrc2;
END ARCHITECTURE behavior;