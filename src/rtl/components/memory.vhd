LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.MATH_REAL.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;

ENTITY memory IS
  GENERIC (
    DATA_WIDTH : INTEGER := 32;
    MEMORY_SIZE : INTEGER := 4096;
    MEM_FILE : STRING := "./out.mem"
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
END memory;

ARCHITECTURE behavioral OF memory IS
  TYPE memory_array IS ARRAY (MEMORY_SIZE - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  -- Function to initialize memory from .mem file
  IMPURE FUNCTION init_memory_from_file(file_name : STRING) RETURN memory_array IS
    FILE mem_file : text;
    VARIABLE file_line : line;
    VARIABLE temp_mem : memory_array := (OTHERS => (OTHERS => '0'));
    VARIABLE good_read : BOOLEAN;
    VARIABLE address_idx : INTEGER := 0;
    VARIABLE data_value : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
  BEGIN
    IF file_name /= "" THEN
      file_open(mem_file, file_name, read_mode);
      WHILE NOT endfile(mem_file) AND address_idx < MEMORY_SIZE LOOP
        readline(mem_file, file_line);
        read(file_line, data_value, good_read);
        IF good_read THEN
          temp_mem(address_idx) := data_value;
          address_idx := address_idx + 1;
        END IF;
      END LOOP;
      file_close(mem_file);
    END IF;
    RETURN temp_mem;
  END FUNCTION;

  SIGNAL mem : memory_array := init_memory_from_file(MEM_FILE);

BEGIN

  PROCESS (clk)
    VARIABLE addr_int : INTEGER;
  BEGIN
    IF falling_edge(clk) THEN
      addr_int := to_integer(unsigned(address));

      IF write_enable = '1' AND addr_int >= 0 AND addr_int < MEMORY_SIZE THEN
        mem(addr_int) <= write_data;
      END IF;

      -- only update when read_enable='1', otherwise hold previous value
      IF read_enable = '1' THEN
        IF addr_int >= 0 AND addr_int < MEMORY_SIZE THEN
          read_data <= mem(addr_int);
        ELSE
          read_data <= (OTHERS => '0');
        END IF;
      END IF;
    END IF;
  END PROCESS;
END behavioral;