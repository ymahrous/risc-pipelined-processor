LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY alu IS
  GENERIC (
    WIDTH : INTEGER := 32
  );
  PORT (
    a : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    ccr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    alu_op : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    result : OUT STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
    ccr_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END ENTITY alu;

ARCHITECTURE behavioral OF alu IS
  
  FUNCTION add_unsigned(a : unsigned; b : unsigned) RETURN unsigned IS
    VARIABLE result : unsigned(a'LENGTH - 1 DOWNTO 0);
    VARIABLE carry : STD_LOGIC := '0';
  BEGIN
    result := (OTHERS => '0');
    FOR i IN 0 TO a'LENGTH - 2 LOOP
      result(i) := (a(i) XOR b(i)) XOR carry;
      carry := (a(i) AND b(i)) OR ((a(i) XOR b(i)) AND carry);
    END LOOP;
    result(a'LENGTH - 1) := carry;
    RETURN result;
  END FUNCTION;
  
  FUNCTION add_one(a : unsigned) RETURN unsigned IS
    VARIABLE result : unsigned(a'LENGTH - 1 DOWNTO 0);
    VARIABLE carry : STD_LOGIC := '1';
  BEGIN
    result := (OTHERS => '0');
    FOR i IN 0 TO a'LENGTH - 2 LOOP
      result(i) := a(i) XOR carry;
      carry := a(i) AND carry;
    END LOOP;
    result(a'LENGTH - 1) := carry;
    RETURN result;
  END FUNCTION;
  
  FUNCTION sub_unsigned(a : unsigned; b : unsigned) RETURN unsigned IS
    VARIABLE b_inv : unsigned(b'LENGTH - 1 DOWNTO 0);
    VARIABLE result : unsigned(a'LENGTH - 1 DOWNTO 0);
  BEGIN
    -- Two's complement: a - b = a + (~b + 1)
    b_inv := NOT b;
    result := add_unsigned(a, b_inv);
    result := add_one(result);
    RETURN result;
  END FUNCTION;

BEGIN
  PROCESS (a, b, ccr, alu_op)
    VARIABLE a_signed : signed(WIDTH - 1 DOWNTO 0);
    VARIABLE b_signed : signed(WIDTH - 1 DOWNTO 0);
    VARIABLE a_unsigned : unsigned(WIDTH - 1 DOWNTO 0);
    VARIABLE b_unsigned : unsigned(WIDTH - 1 DOWNTO 0);
    VARIABLE result_int : signed(WIDTH - 1 DOWNTO 0);
    VARIABLE result_unsigned : unsigned(WIDTH DOWNTO 0); -- extra bit for carry detection
    VARIABLE carry_flag : STD_LOGIC;
    VARIABLE zero_flag : STD_LOGIC;
    VARIABLE neg_flag : STD_LOGIC;
  BEGIN
    a_signed := signed(a);
    b_signed := signed(b);
    a_unsigned := unsigned(a);
    b_unsigned := unsigned(b);
    result_int := (OTHERS => '0');
    result_unsigned := (OTHERS => '0');
    carry_flag := ccr(2);
    neg_flag := ccr(1);
    zero_flag := ccr(0);

    CASE alu_op IS
      WHEN "000" => -- f = a
        result_int := a_signed;

      WHEN "001" => -- f = b
        result_int := b_signed;

      WHEN "010" => -- setc (set carry flag)
        result_int := a_signed;
        carry_flag := '1';

      WHEN "011" => -- f = not a
        result_int := NOT a_signed;

      WHEN "100" => -- f = a + 1
        result_unsigned := add_one(resize(a_unsigned, WIDTH + 1));
        result_int := signed(result_unsigned(WIDTH - 1 DOWNTO 0));
        carry_flag := result_unsigned(WIDTH);

      WHEN "101" => -- f = a + b
        result_unsigned := add_unsigned(resize(a_unsigned, WIDTH + 1), resize(b_unsigned, WIDTH + 1));
        result_int := signed(result_unsigned(WIDTH - 1 DOWNTO 0));
        carry_flag := result_unsigned(WIDTH);

      WHEN "110" => -- f = a - b
        result_unsigned := sub_unsigned(resize(a_unsigned, WIDTH + 1), resize(b_unsigned, WIDTH + 1));
        result_int := signed(result_unsigned(WIDTH - 1 DOWNTO 0));
        carry_flag := result_unsigned(WIDTH); -- borrow flag

      WHEN "111" => -- f = a and b
        result_int := a_signed AND b_signed;

      WHEN OTHERS =>
        result_int := a_signed;
    END CASE;

    -- Update zero flag
    IF result_int = 0 THEN
      zero_flag := '1';
    ELSE
      zero_flag := '0';
    END IF;

    neg_flag := result_int(WIDTH - 1);
    result <= STD_LOGIC_VECTOR(result_int);
    ccr_out(0) <= zero_flag;
    ccr_out(1) <= neg_flag;
    ccr_out(2) <= carry_flag;

  END PROCESS;
END ARCHITECTURE behavioral;