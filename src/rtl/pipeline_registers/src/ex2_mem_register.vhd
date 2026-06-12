library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ex2_mem_register IS
    GENERIC (
        WIDTH : INTEGER := 32
    );
    PORT (
        clk   : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        stall : IN STD_LOGIC;

        ccr                     : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_write_sel           : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        wb_enable_in            : IN STD_LOGIC;
        output_sel              : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel             : IN STD_LOGIC;
        mem_read_write_enable   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel         : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push                 : IN STD_LOGIC;
        sp_write_enable         : IN STD_LOGIC;
        swap_in                 : IN STD_LOGIC;

        alu_result_in           : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        read_data_2_in          : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        index_in                : IN STD_LOGIC;
        next_pc_in              : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        wb_address_in           : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        ccr_out                     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_write_sel_out           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        wb_enable_out               : OUT STD_LOGIC;
        output_sel_out              : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_out             : OUT STD_LOGIC;
        mem_read_write_enable_out   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel_out         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push_out                 : OUT STD_LOGIC;
        sp_write_enable_out         : OUT STD_LOGIC;
        swap_out                    : OUT STD_LOGIC;

        alu_result_out  : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        read_data_2_out : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        index_out       : OUT STD_LOGIC;
        next_pc_out     : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
        wb_address_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY ex2_mem_register;

ARCHITECTURE behavioral OF ex2_mem_register IS
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF reset = '0' THEN
            ccr_out                   <= (OTHERS => '0');
            mem_write_sel_out         <= "00";
            wb_enable_out             <= '0';
            output_sel_out            <= "11";
            alu_mem_sel_out           <= '0';
            mem_read_write_enable_out <= "00";
            mem_address_sel_out       <= "10";
            is_push_out               <= '0';
            sp_write_enable_out       <= '0';
            swap_out                  <= '0';
            alu_result_out            <= (OTHERS => '0');
            read_data_2_out           <= (OTHERS => '0');
            index_out                 <= '0';
            next_pc_out               <= (OTHERS => '0');
            wb_address_out            <= (OTHERS => '0');

        ELSIF rising_edge(clk) THEN
            IF stall = '0' THEN
                ccr_out                   <= ccr;
                mem_write_sel_out         <= mem_write_sel;
                wb_enable_out             <= wb_enable_in;
                output_sel_out            <= output_sel;
                alu_mem_sel_out           <= alu_mem_sel;
                mem_read_write_enable_out <= mem_read_write_enable;
                mem_address_sel_out       <= mem_address_sel;
                is_push_out               <= is_push;
                sp_write_enable_out       <= sp_write_enable;
                swap_out                  <= swap_in;
                alu_result_out            <= alu_result_in;
                read_data_2_out           <= read_data_2_in;
                index_out                 <= index_in;
                next_pc_out               <= next_pc_in;
                wb_address_out            <= wb_address_in;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;