LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY REGISTERS IS
    PORT (
        write_address : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        write_enable, clk, reset : IN STD_LOGIC;
        read_address_1, read_address_2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data_1, read_data_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        r0, r1, r2, r3, r4, r5, r6, r7 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY REGISTERS;

ARCHITECTURE behavioral OF REGISTERS IS
    COMPONENT dff
        PORT (
            d : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            clk, reset : IN STD_LOGIC;
            q : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    TYPE reg_array IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL outputs_signals : reg_array := (OTHERS => (OTHERS => '0'));
BEGIN

    PROCESS (clk, reset)
    BEGIN
        IF reset = '0' THEN
            outputs_signals <= (OTHERS => (OTHERS => '0'));
        ELSIF falling_edge(clk) THEN
            IF write_enable = '1' THEN
                outputs_signals(to_integer(unsigned(write_address))) <= write_data;
            END IF;
        END IF;
    END PROCESS;

    read_data_1 <= outputs_signals(to_integer(unsigned(read_address_1)));
    read_data_2 <= outputs_signals(to_integer(unsigned(read_address_2)));

    r0 <= outputs_signals(0);
    r1 <= outputs_signals(1);
    r2 <= outputs_signals(2);
    r3 <= outputs_signals(3);
    r4 <= outputs_signals(4);
    r5 <= outputs_signals(5);
    r6 <= outputs_signals(6);
    r7 <= outputs_signals(7);
END ARCHITECTURE behavioral;