-- ============================================================
-- processor.vhd  –  NEW (6-stage) ISA
--
-- Pipeline:  IF → ID → EX1 → EX2 → MEM → WB
--
-- Key differences from old (5-stage) processor.vhd:
--   • New EX1/EX2 pipeline register between execute and memory
--   • execute2_stage instance for branch resolution in EX2
--   • Conditional-branch flush now kills IF/ID AND ID/EX1
--   • Forwarding unit has 3 sources (adds EX1/EX2 path)
--   • Hazard unit updated for 2-cycle load-use window
--   • Memory size 4 096 words (4 KB)
--   • SP reset = 2^12-1 (in sp_unit)
--   • PUSH/OUT encoding: register in Rsrc1 [26:24]
-- ============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY processor IS
    GENERIC (
        MEM_FILE : STRING := "./out.mem"
    );
    PORT (
        clk      : IN  STD_LOGIC;
        reset    : IN  STD_LOGIC;
        int      : IN  STD_LOGIC;
        in_port  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_port : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END processor;

ARCHITECTURE behavioral OF processor IS

    -- -------------------------------------------------------
    -- Component declarations
    -- -------------------------------------------------------
    COMPONENT control_unit IS PORT(
        opcode : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        clk, int, reset : IN STD_LOGIC;
        popped_pc    : OUT STD_LOGIC;
        pc_en        : OUT STD_LOGIC;
        imm_jump     : OUT STD_LOGIC;
        jmp_cond_or_none : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        if_id_enable : OUT STD_LOGIC;
        if_id_flush  : OUT STD_LOGIC;
        id_ex1_flush : OUT STD_LOGIC;
        swap_or_1op  : OUT STD_LOGIC;
        wb_address_sel : OUT STD_LOGIC;
        mem_write_sel : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        wb_enable     : OUT STD_LOGIC;
        output_sel    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_or_mem    : OUT STD_LOGIC;
        is_push       : OUT STD_LOGIC;
        sp_write_enable : OUT STD_LOGIC;
        mem_read_write_enable : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_addr_sel  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_src_sel   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_func      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        alu_mem_wb_sel : OUT STD_LOGIC;
        ccr_enable    : OUT STD_LOGIC;
        swap_out      : OUT STD_LOGIC;
        idx_popped_pc_immediate_out : OUT STD_LOGIC;
        ext_int_read_m1 : OUT STD_LOGIC
    ); END COMPONENT;

    COMPONENT fetch_stage IS GENERIC(width : INTEGER := 32); PORT(
        clk : IN STD_LOGIC; rst : IN STD_LOGIC; pc_en_in : IN STD_LOGIC;
        popped_pc_cs : IN STD_LOGIC; hw_cs : IN STD_LOGIC;
        imm_jump_cs : IN STD_LOGIC; jump_cond_cs : IN STD_LOGIC;
        popped_pc : IN STD_LOGIC_VECTOR(width-1 DOWNTO 0);
        hw_pc     : IN STD_LOGIC_VECTOR(width-1 DOWNTO 0);
        imm_jump  : IN STD_LOGIC_VECTOR(width-1 DOWNTO 0);
        next_pc   : OUT STD_LOGIC_VECTOR(width-1 DOWNTO 0);
        pc_out    : OUT STD_LOGIC_VECTOR(width-1 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT memory_wrapper IS GENERIC(DATA_WIDTH : INTEGER := 32; MEMORY_SIZE : INTEGER := 4096; MEM_FILE : STRING := "./out.mem"); PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC;
        fetch_or_mem : IN STD_LOGIC;
        fetch_data   : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        mem_address  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_write_data : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        mem_read_data  : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        mem_read_enable  : IN STD_LOGIC;
        mem_write_enable : IN STD_LOGIC;
        read_enable_selector : IN STD_LOGIC;
        INT_extended : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        PC           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        hardware_signal : IN STD_LOGIC;
        hw_address   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT if_id_register IS GENERIC(WIDTH : INTEGER := 32); PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC; stall : IN STD_LOGIC; flush : IN STD_LOGIC;
        in_port_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        next_pc_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        instruction_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        imm_follows : IN STD_LOGIC;
        next_pc_out    : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        instruction_out : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        in_port_out    : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT decode IS PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC;
        sw_c_1_op : IN STD_LOGIC; wb_addr_sel : IN STD_LOGIC;
        Rsrc1, Rsrc2, Rdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        write_reg    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        write_data   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        write_enable : IN STD_LOGIC;
        wb_address_o    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_address1_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_address2_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        read_data2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        r0,r1,r2,r3,r4,r5,r6,r7 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT id_ex1_register IS GENERIC(WIDTH : INTEGER := 32); PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC; stall : IN STD_LOGIC;
        flush : IN STD_LOGIC;
        in_port_in  : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        alu_func_sel : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        alu_src_sel  : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        swap_in      : IN STD_LOGIC;
        jump_cond_or_none : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_write_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        output_sel   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel  : IN STD_LOGIC;
        mem_read_write_enable : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push      : IN STD_LOGIC;
        sp_write_enable : IN STD_LOGIC;
        wb_enable    : IN STD_LOGIC;
        ccr_enable_in : IN STD_LOGIC;
        next_pc_in   : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_1_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_2_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        immediate_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        index_in     : IN STD_LOGIC;
        wb_address_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_address_1_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_address_2_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data_1_out  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_2_out  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        immediate_out    : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        index_out        : OUT STD_LOGIC;
        next_pc_out      : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        wb_address_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        alu_func_sel_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        alu_src_sel_out  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        jump_cond_or_none_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_write_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        output_sel_out    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_out   : OUT STD_LOGIC;
        mem_read_write_enable_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        swap_out         : OUT STD_LOGIC;
        mem_address_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push_out      : OUT STD_LOGIC;
        sp_write_enable_out : OUT STD_LOGIC;
        wb_enable_out    : OUT STD_LOGIC;
        in_port_out      : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        ccr_enable_out   : OUT STD_LOGIC;
        read_address_1_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_address_2_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT execute1_stage IS GENERIC(WIDTH : INTEGER := 32); PORT(
        clk : IN STD_LOGIC;
        read_data_1 : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_2 : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        immiediate_value : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        ccr_write_back   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ccr_enable       : IN STD_LOGIC;
        write_back_forwarding_data : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        alu_forwarding_data        : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        alu_forwarding_data_ex2    : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        fu_data_1_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        fu_data_2_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_input_selection : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_op              : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ccr_write_back_en   : IN STD_LOGIC;
        reset               : IN STD_LOGIC;
        reset_ccr_z : IN STD_LOGIC;
        reset_ccr_n : IN STD_LOGIC;
        reset_ccr_c : IN STD_LOGIC;
        in_port     : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        alu_rsrc2_out : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        alu_result    : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        ccr_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT ex1_ex2_register IS GENERIC(WIDTH : INTEGER := 32); PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC;
        flush : IN STD_LOGIC; stall : IN STD_LOGIC;
        alu_result_in  : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_2_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        ccr_in         : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        next_pc_in     : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        wb_address_in  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        index_in       : IN STD_LOGIC;
        jump_cond_or_none_in      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_write_sel_in          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        output_sel_in             : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_in            : IN STD_LOGIC;
        mem_read_write_enable_in  : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel_in        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push_in                : IN STD_LOGIC;
        sp_write_enable_in        : IN STD_LOGIC;
        wb_enable_in              : IN STD_LOGIC;
        swap_in                   : IN STD_LOGIC;
        alu_result_out  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_2_out : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        ccr_out         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        next_pc_out     : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        wb_address_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        index_out       : OUT STD_LOGIC;
        jump_cond_or_none_out     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_write_sel_out         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        output_sel_out            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_out           : OUT STD_LOGIC;
        mem_read_write_enable_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel_out       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push_out               : OUT STD_LOGIC;
        sp_write_enable_out       : OUT STD_LOGIC;
        wb_enable_out             : OUT STD_LOGIC;
        swap_out                  : OUT STD_LOGIC
    ); END COMPONENT;

    COMPONENT execute2_stage IS GENERIC(WIDTH : INTEGER := 32); PORT(
        ccr_in             : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        jump_cond_or_none  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        jump_taken         : OUT STD_LOGIC;
        reset_ccr_z        : OUT STD_LOGIC;
        reset_ccr_n        : OUT STD_LOGIC;
        reset_ccr_c        : OUT STD_LOGIC
    ); END COMPONENT;

    COMPONENT ex2_mem_register IS GENERIC(WIDTH : INTEGER := 32); PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC; stall : IN STD_LOGIC;
        ccr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_write_sel  : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        wb_enable_in   : IN STD_LOGIC;
        output_sel     : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel    : IN STD_LOGIC;
        mem_read_write_enable : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push        : IN STD_LOGIC;
        sp_write_enable : IN STD_LOGIC;
        swap_in        : IN STD_LOGIC;
        alu_result_in  : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_2_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        index_in       : IN STD_LOGIC;
        next_pc_in     : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        wb_address_in  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ccr_out                   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_write_sel_out         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        wb_enable_out             : OUT STD_LOGIC;
        output_sel_out            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_out           : OUT STD_LOGIC;
        mem_read_write_enable_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel_out       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        is_push_out               : OUT STD_LOGIC;
        sp_write_enable_out       : OUT STD_LOGIC;
        swap_out                  : OUT STD_LOGIC;
        alu_result_out  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        read_data_2_out : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        index_out       : OUT STD_LOGIC;
        next_pc_out     : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        wb_address_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT memory_stage IS GENERIC(DATA_WIDTH:INTEGER:=32; ADDR_WIDTH:INTEGER:=32; MEMORY_SIZE:INTEGER:=4096); PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC;
        alu_result : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        index      : IN STD_LOGIC;
        read_data_2 : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        next_pc    : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        mem_write_sel  : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_address_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        sp_write_enable : IN STD_LOGIC;
        is_push        : IN STD_LOGIC;
        ccr_in         : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_address    : OUT STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
        mem_write_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        sp_out         : OUT STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT mem_wb_register IS GENERIC(WIDTH : INTEGER := 32); PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC; stall : IN STD_LOGIC;
        wb_enable_in : IN STD_LOGIC;
        output_sel   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel  : IN STD_LOGIC;
        read_data_in  : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        alu_result_in : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        wb_address_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        wb_enable_out  : OUT STD_LOGIC;
        output_sel_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel_out : OUT STD_LOGIC;
        read_data_out  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        alu_result_out : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        wb_address_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT writeback_stage IS GENERIC(DATA_WIDTH : INTEGER := 32); PORT(
        output_sel  : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_mem_sel : IN STD_LOGIC;
        alu_result  : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        mem_read_data : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        ccr_extended  : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        popped_PC     : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        write_back_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        output_port   : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT imm_detect IS PORT(
        clk : IN STD_LOGIC; reset : IN STD_LOGIC;
        instruction : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        imm_follows : OUT STD_LOGIC;
        cur_is_imm  : OUT STD_LOGIC
    ); END COMPONENT;

    COMPONENT forwarding_unit IS PORT(
        read_reg_1_addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_reg_2_addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        swap            : IN STD_LOGIC;
        ex1_ex2_wb_addr   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ex1_ex2_wb_enable : IN STD_LOGIC;
        ex1_ex2_mem_read  : IN STD_LOGIC;
        ex2_mem_wb_addr   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ex2_mem_wb_enable : IN STD_LOGIC;
        ex2_mem_mem_read  : IN STD_LOGIC;
        mem_wb_addr   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_wb_enable : IN STD_LOGIC;
        forward_a    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        forward_b    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        load_use_ex2 : OUT STD_LOGIC;
        load_use_mem : OUT STD_LOGIC
    ); END COMPONENT;

    COMPONENT hazard_control_unit IS PORT(
        load_use_ex2     : IN STD_LOGIC;
        load_use_mem     : IN STD_LOGIC;
        mem_read_active  : IN STD_LOGIC;
        mem_write_active : IN STD_LOGIC;
        stall_pc         : OUT STD_LOGIC;
        stall_if_id      : OUT STD_LOGIC;
        stall_id_ex1     : OUT STD_LOGIC;
        flush_ex1_ex2    : OUT STD_LOGIC;
        pc_enable        : OUT STD_LOGIC;
        fetch_or_memory  : OUT STD_LOGIC
    ); END COMPONENT;

    -- -------------------------------------------------------
    -- Internal signals
    -- -------------------------------------------------------
    -- CU outputs
    SIGNAL cu_popped_pc_cs, cu_imm_jump_cs       : STD_LOGIC;
    SIGNAL cu_jump_or_none                        : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL cu_if_id_enable, cu_if_id_flush        : STD_LOGIC;
    SIGNAL cu_id_ex1_flush                        : STD_LOGIC;
    SIGNAL cu_swap_or_1op, cu_wb_addr_sel         : STD_LOGIC;
    SIGNAL cu_mem_write_sel                       : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL cu_wb_enable                           : STD_LOGIC;
    SIGNAL cu_output_sel                          : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL cu_alu_or_mem                          : STD_LOGIC;
    SIGNAL cu_is_push, cu_sp_write_enable         : STD_LOGIC;
    SIGNAL cu_mem_read_write_enable               : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL cu_mem_addr_sel, cu_alu_src_sel        : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL cu_alu_func                            : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL cu_alu_mem_wb_sel, cu_ccr_enable       : STD_LOGIC;
    SIGNAL cu_swap_out                            : STD_LOGIC;
    SIGNAL cu_idx_popped_pc_imm                   : STD_LOGIC;
    SIGNAL cu_ext_int_read_m1                     : STD_LOGIC;
    SIGNAL cu_pc_enable                           : STD_LOGIC;

    -- Fetch
    SIGNAL pc_out, next_pc                        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fetched_instruction                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL hw_pc_address                          : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem_read_data_out                      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL imm_follows, imm_cur_is_imm            : STD_LOGIC;
    SIGNAL imm_jump_mux_out                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL int_address_one                        : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000001";
    SIGNAL ext_int_mem_address                    : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- IF/ID outputs
    SIGNAL next_pc_if_id, inst_out_if_id          : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL in_port_if_id                          : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Decode outputs
    SIGNAL decode_rd1, decode_rd2                 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_read_addr1, decode_read_addr2   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL decode_wb_addr                         : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL r0,r1,r2,r3,r4,r5,r6,r7               : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- ID/EX1 outputs
    SIGNAL rd1_idex, rd2_idex, imm_idex           : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL idx_idex                               : STD_LOGIC;
    SIGNAL npc_idex                               : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL wba_idex                               : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL alu_func_idex                          : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL alu_src_idex                           : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL jcond_idex                             : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL mws_idex                               : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL osel_idex                              : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ams_idex                               : STD_LOGIC;
    SIGNAL mrwe_idex                              : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL masel_idex                             : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ispush_idex, spwe_idex, wbe_idex       : STD_LOGIC;
    SIGNAL ccren_idex, swap_idex                  : STD_LOGIC;
    SIGNAL inport_idex                            : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL raddr1_idex, raddr2_idex               : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- EX1 outputs
    SIGNAL ex1_alu_result, ex1_rsrc2              : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ex1_ccr                                : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- EX1/EX2 register outputs
    SIGNAL ar_ex1ex2, rd2_ex1ex2                  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ccr_ex1ex2                             : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL npc_ex1ex2                             : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL wba_ex1ex2                             : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL idx_ex1ex2                             : STD_LOGIC;
    SIGNAL jcond_ex1ex2                           : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL mws_ex1ex2                             : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL osel_ex1ex2                            : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ams_ex1ex2                             : STD_LOGIC;
    SIGNAL mrwe_ex1ex2                            : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL masel_ex1ex2                           : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ispush_ex1ex2, spwe_ex1ex2, wbe_ex1ex2 : STD_LOGIC;
    SIGNAL swap_ex1ex2                            : STD_LOGIC;

    -- EX2 outputs
    SIGNAL ex2_jump_taken                         : STD_LOGIC;
    SIGNAL ex2_reset_z, ex2_reset_n, ex2_reset_c  : STD_LOGIC;

    -- EX2/MEM register outputs
    SIGNAL ccr_ex2mem                             : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL mws_ex2mem                             : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL wbe_ex2mem                             : STD_LOGIC;
    SIGNAL osel_ex2mem                            : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ams_ex2mem                             : STD_LOGIC;
    SIGNAL mrwe_ex2mem                            : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL masel_ex2mem                           : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ispush_ex2mem, spwe_ex2mem             : STD_LOGIC;
    SIGNAL swap_ex2mem                            : STD_LOGIC;
    SIGNAL ar_ex2mem, rd2_ex2mem                  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL idx_ex2mem                             : STD_LOGIC;
    SIGNAL npc_ex2mem                             : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL wba_ex2mem                             : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- MEM stage outputs
    SIGNAL mem_address, mem_write_data            : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL sp_value                               : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- MEM/WB register outputs
    SIGNAL wbe_memwb, ams_memwb                   : STD_LOGIC;
    SIGNAL osel_memwb                             : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL rd_memwb, ar_memwb                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL wba_memwb                              : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- WB outputs
    SIGNAL ccr_ext_wb, popped_pc_wb               : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL wb_data, out_port_sig                  : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Forwarding
    SIGNAL fu_fwd_a, fu_fwd_b                     : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL fu_load_use_ex2, fu_load_use_mem        : STD_LOGIC;

    -- Hazard
    SIGNAL hcu_stall_pc, hcu_stall_if_id          : STD_LOGIC;
    SIGNAL hcu_stall_id_ex1, hcu_flush_ex1ex2     : STD_LOGIC;
    SIGNAL hcu_pc_enable, hcu_fetch_or_memory     : STD_LOGIC;

    -- CCR write-back from MEM path
    SIGNAL ccr_wb_from_mem                        : STD_LOGIC;

BEGIN

    -- -------- misc combinational --------
    imm_jump_mux_out <= fetched_instruction WHEN cu_imm_jump_cs = '1' ELSE imm_idex;
    ext_int_mem_address <= int_address_one WHEN cu_ext_int_read_m1 = '1' ELSE mem_address;

    ccr_wb_from_mem <= '1' WHEN (osel_memwb = "00" AND ams_memwb = '0') ELSE '0';
    -- Registered output port: holds value until next OUT instruction
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '0' THEN
                out_port <= (OTHERS => '0');
            ELSIF osel_memwb = "10" THEN  -- output_sel "10" = OUT instruction in WB
                out_port <= out_port_sig;
            END IF;
            -- else: hold previous value (waveform stays stable)
        END IF;
    END PROCESS;

    -- ======================================================
    -- FETCH STAGE
    -- ======================================================
    fetch_inst : fetch_stage
    GENERIC MAP(width => 32)
    PORT MAP(
        clk => clk, rst => reset,
        pc_en_in     => (cu_pc_enable AND hcu_pc_enable) OR cu_idx_popped_pc_imm,
        popped_pc_cs => cu_popped_pc_cs OR cu_idx_popped_pc_imm,
        hw_cs        => NOT reset,
        imm_jump_cs  => cu_imm_jump_cs,
        jump_cond_cs => ex2_jump_taken,   -- branch resolved in EX2 (NEW)
        popped_pc    => popped_pc_wb,
        hw_pc        => hw_pc_address,
        imm_jump     => imm_jump_mux_out,
        next_pc      => next_pc,
        pc_out       => pc_out
    );

    -- ======================================================
    -- MEMORY WRAPPER  (Von Neumann: shared fetch/data port)
    -- ======================================================
    mem_inst : memory_wrapper
    GENERIC MAP(DATA_WIDTH => 32, MEMORY_SIZE => 4096, MEM_FILE => MEM_FILE)
    PORT MAP(
        clk => clk, reset => reset,
        fetch_or_mem     => hcu_fetch_or_memory OR cu_ext_int_read_m1,
        fetch_data       => fetched_instruction,
        mem_address      => ext_int_mem_address,
        mem_write_data   => mem_write_data,
        mem_read_enable  => mrwe_ex2mem(1),
        mem_write_enable => mrwe_ex2mem(0),
        read_enable_selector => reset AND (hcu_fetch_or_memory OR cu_ext_int_read_m1),
        INT_extended     => (OTHERS => '0'),
        PC               => pc_out,
        hardware_signal  => NOT reset,
        mem_read_data    => mem_read_data_out,
        hw_address       => hw_pc_address
    );

    -- ======================================================
    -- IMM DETECT
    -- ======================================================
    imm_detect_inst : imm_detect
    PORT MAP(clk => clk, reset => reset,
             instruction => fetched_instruction,
             imm_follows => imm_follows,
             cur_is_imm  => imm_cur_is_imm);

    -- ======================================================
    -- IF/ID REGISTER
    -- ======================================================
    if_id_inst : if_id_register
    GENERIC MAP(WIDTH => 32)
    PORT MAP(
        clk   => clk,
        reset => reset AND NOT ex2_jump_taken,  -- flush on branch (EX2)
        stall => NOT cu_if_id_enable OR (hcu_fetch_or_memory AND imm_follows),
        flush => cu_if_id_flush OR imm_follows OR ex2_jump_taken,
        in_port_in      => in_port,
        next_pc_in      => next_pc,
        instruction_in  => fetched_instruction,
        imm_follows     => imm_follows,
        next_pc_out     => next_pc_if_id,
        instruction_out => inst_out_if_id,
        in_port_out     => in_port_if_id
    );

    -- ======================================================
    -- DECODE / REGISTER FILE
    -- ======================================================
    decode_inst : decode
    PORT MAP(
        clk => clk, reset => reset,
        sw_c_1_op   => cu_swap_or_1op,
        wb_addr_sel => cu_wb_addr_sel,
        Rsrc1 => inst_out_if_id(26 DOWNTO 24),
        Rsrc2 => inst_out_if_id(23 DOWNTO 21),
        Rdst  => inst_out_if_id(20 DOWNTO 18),
        write_reg    => wba_memwb,
        write_data   => wb_data,
        write_enable => wbe_memwb,
        wb_address_o    => decode_wb_addr,
        read_address1_o => decode_read_addr1,
        read_address2_o => decode_read_addr2,
        read_data1 => decode_rd1,
        read_data2 => decode_rd2,
        r0=>r0, r1=>r1, r2=>r2, r3=>r3, r4=>r4, r5=>r5, r6=>r6, r7=>r7
    );

    -- ======================================================
    -- CONTROL UNIT
    -- ======================================================
    cu_inst : control_unit
    PORT MAP(
        opcode => inst_out_if_id(31 DOWNTO 27),
        clk => clk, int => int, reset => reset,
        popped_pc    => cu_popped_pc_cs,
        pc_en        => cu_pc_enable,
        imm_jump     => cu_imm_jump_cs,
        jmp_cond_or_none => cu_jump_or_none,
        if_id_enable => cu_if_id_enable,
        if_id_flush  => cu_if_id_flush,
        id_ex1_flush => cu_id_ex1_flush,
        swap_or_1op  => cu_swap_or_1op,
        wb_address_sel => cu_wb_addr_sel,
        mem_write_sel => cu_mem_write_sel,
        wb_enable     => cu_wb_enable,
        output_sel    => cu_output_sel,
        alu_or_mem    => cu_alu_or_mem,
        is_push       => cu_is_push,
        sp_write_enable => cu_sp_write_enable,
        mem_read_write_enable => cu_mem_read_write_enable,
        mem_addr_sel  => cu_mem_addr_sel,
        alu_src_sel   => cu_alu_src_sel,
        alu_func      => cu_alu_func,
        alu_mem_wb_sel => cu_alu_mem_wb_sel,
        ccr_enable    => cu_ccr_enable,
        swap_out      => cu_swap_out,
        idx_popped_pc_immediate_out => cu_idx_popped_pc_imm,
        ext_int_read_m1 => cu_ext_int_read_m1
    );

    -- ======================================================
    -- ID/EX1 REGISTER  (flush on branch taken from EX2)
    -- ======================================================
    id_ex1_inst : id_ex1_register
    GENERIC MAP(WIDTH => 32)
    PORT MAP(
        clk   => clk,
        reset => reset AND NOT (hcu_fetch_or_memory AND imm_follows),
        stall => '0',
        flush => cu_id_ex1_flush OR ex2_jump_taken,  -- NEW: also flush on EX2 branch
        alu_func_sel => cu_alu_func,
        alu_src_sel  => cu_alu_src_sel,
        swap_in      => cu_swap_out,
        jump_cond_or_none => cu_jump_or_none,
        mem_write_sel => cu_mem_write_sel,
        output_sel   => cu_output_sel,
        alu_mem_sel  => cu_alu_mem_wb_sel,
        mem_read_write_enable => cu_mem_read_write_enable,
        mem_address_sel => cu_mem_addr_sel,
        is_push      => cu_is_push,
        sp_write_enable => cu_sp_write_enable,
        in_port_in   => in_port_if_id,
        wb_enable    => cu_wb_enable,
        ccr_enable_in => cu_ccr_enable,
        next_pc_in   => next_pc_if_id,
        read_data_1_in => decode_rd1,
        read_data_2_in => decode_rd2,
        immediate_in => fetched_instruction,
        index_in     => inst_out_if_id(17),
        wb_address_in => decode_wb_addr,
        read_address_1_in => decode_read_addr1,
        read_address_2_in => decode_read_addr2,
        read_data_1_out  => rd1_idex,
        read_data_2_out  => rd2_idex,
        immediate_out    => imm_idex,
        index_out        => idx_idex,
        next_pc_out      => npc_idex,
        wb_address_out   => wba_idex,
        alu_func_sel_out => alu_func_idex,
        alu_src_sel_out  => alu_src_idex,
        jump_cond_or_none_out => jcond_idex,
        mem_write_sel_out => mws_idex,
        output_sel_out    => osel_idex,
        alu_mem_sel_out   => ams_idex,
        mem_read_write_enable_out => mrwe_idex,
        swap_out         => swap_idex,
        mem_address_sel_out => masel_idex,
        is_push_out      => ispush_idex,
        sp_write_enable_out => spwe_idex,
        wb_enable_out    => wbe_idex,
        in_port_out      => inport_idex,
        ccr_enable_out   => ccren_idex,
        read_address_1_out => raddr1_idex,
        read_address_2_out => raddr2_idex
    );

    -- ======================================================
    -- EXECUTE-1 STAGE  (ALU operations)
    -- ======================================================
    ex1_inst : execute1_stage
    GENERIC MAP(WIDTH => 32)
    PORT MAP(
        clk => clk,
        read_data_1 => rd1_idex,
        read_data_2 => rd2_idex,
        immiediate_value => imm_idex,
        ccr_write_back   => ccr_ext_wb(2 DOWNTO 0),
        ccr_enable       => ccren_idex OR ccr_wb_from_mem,
        -- Forwarding: 3-input mux ("11"=EX1/EX2, "10"=EX2/MEM, "01"=MEM/WB)
        write_back_forwarding_data => wb_data,
        alu_forwarding_data        => ar_ex2mem,   -- EX2/MEM path
        alu_forwarding_data_ex2    => ar_ex1ex2,   -- EX1/EX2 path (NEW)
        fu_data_1_sel => fu_fwd_a,
        fu_data_2_sel => fu_fwd_b,
        alu_input_selection => alu_src_idex,
        alu_op              => alu_func_idex,
        ccr_write_back_en   => ccr_wb_from_mem,
        reset => reset,
        reset_ccr_z => ex2_reset_z,
        reset_ccr_n => ex2_reset_n,
        reset_ccr_c => ex2_reset_c,
        in_port     => inport_idex,
        alu_rsrc2_out => ex1_rsrc2,
        alu_result    => ex1_alu_result,
        ccr_out       => ex1_ccr
    );

    -- ======================================================
    -- EX1/EX2 PIPELINE REGISTER  (NEW)
    -- ======================================================
    ex1_ex2_reg : ex1_ex2_register
    GENERIC MAP(WIDTH => 32)
    PORT MAP(
        clk => clk, reset => reset,
        flush => hcu_flush_ex1ex2,
        stall => '0',
        alu_result_in  => ex1_alu_result,
        read_data_2_in => ex1_rsrc2,
        ccr_in         => ex1_ccr,
        next_pc_in     => npc_idex,
        wb_address_in  => wba_idex,
        index_in       => idx_idex,
        jump_cond_or_none_in      => jcond_idex,
        mem_write_sel_in          => mws_idex,
        output_sel_in             => osel_idex,
        alu_mem_sel_in            => ams_idex,
        mem_read_write_enable_in  => mrwe_idex,
        mem_address_sel_in        => masel_idex,
        is_push_in                => ispush_idex,
        sp_write_enable_in        => spwe_idex,
        wb_enable_in              => wbe_idex,
        swap_in                   => swap_idex,
        alu_result_out  => ar_ex1ex2,
        read_data_2_out => rd2_ex1ex2,
        ccr_out         => ccr_ex1ex2,
        next_pc_out     => npc_ex1ex2,
        wb_address_out  => wba_ex1ex2,
        index_out       => idx_ex1ex2,
        jump_cond_or_none_out     => jcond_ex1ex2,
        mem_write_sel_out         => mws_ex1ex2,
        output_sel_out            => osel_ex1ex2,
        alu_mem_sel_out           => ams_ex1ex2,
        mem_read_write_enable_out => mrwe_ex1ex2,
        mem_address_sel_out       => masel_ex1ex2,
        is_push_out               => ispush_ex1ex2,
        sp_write_enable_out       => spwe_ex1ex2,
        wb_enable_out             => wbe_ex1ex2,
        swap_out                  => swap_ex1ex2
    );

    -- ======================================================
    -- EXECUTE-2 STAGE  (branch resolution)
    -- ======================================================
    ex2_inst : execute2_stage
    GENERIC MAP(WIDTH => 32)
    PORT MAP(
        ccr_in            => ccr_ex1ex2,
        jump_cond_or_none => jcond_ex1ex2,
        jump_taken        => ex2_jump_taken,
        reset_ccr_z       => ex2_reset_z,
        reset_ccr_n       => ex2_reset_n,
        reset_ccr_c       => ex2_reset_c
    );

    -- ======================================================
    -- EX2/MEM PIPELINE REGISTER
    -- ======================================================
    ex2_mem_reg : ex2_mem_register
    GENERIC MAP(WIDTH => 32)
    PORT MAP(
        clk => clk, reset => reset, stall => '0',
        ccr             => ccr_ex1ex2,
        mem_write_sel   => mws_ex1ex2,
        wb_enable_in    => wbe_ex1ex2,
        output_sel      => osel_ex1ex2,
        alu_mem_sel     => ams_ex1ex2,
        mem_read_write_enable => mrwe_ex1ex2,
        mem_address_sel => masel_ex1ex2,
        is_push         => ispush_ex1ex2,
        sp_write_enable => spwe_ex1ex2,
        swap_in         => swap_ex1ex2,
        alu_result_in   => ar_ex1ex2,
        read_data_2_in  => rd2_ex1ex2,
        index_in        => idx_ex1ex2,
        next_pc_in      => npc_ex1ex2,
        wb_address_in   => wba_ex1ex2,
        ccr_out                   => ccr_ex2mem,
        mem_write_sel_out         => mws_ex2mem,
        wb_enable_out             => wbe_ex2mem,
        output_sel_out            => osel_ex2mem,
        alu_mem_sel_out           => ams_ex2mem,
        mem_read_write_enable_out => mrwe_ex2mem,
        mem_address_sel_out       => masel_ex2mem,
        is_push_out               => ispush_ex2mem,
        sp_write_enable_out       => spwe_ex2mem,
        swap_out                  => swap_ex2mem,
        alu_result_out            => ar_ex2mem,
        read_data_2_out           => rd2_ex2mem,
        index_out                 => idx_ex2mem,
        next_pc_out               => npc_ex2mem,
        wb_address_out            => wba_ex2mem
    );

    -- ======================================================
    -- MEMORY STAGE
    -- ======================================================
    mem_stage_inst : memory_stage
    GENERIC MAP(DATA_WIDTH => 32, ADDR_WIDTH => 32, MEMORY_SIZE => 4096)
    PORT MAP(
        clk => clk, reset => reset,
        alu_result  => ar_ex2mem,
        index       => idx_ex2mem,
        read_data_2 => rd2_ex2mem,
        next_pc     => npc_ex2mem,
        mem_write_sel   => mws_ex2mem,
        mem_address_sel => masel_ex2mem,
        sp_write_enable => spwe_ex2mem,
        is_push         => ispush_ex2mem,
        ccr_in          => ccr_ex2mem,
        mem_address     => mem_address,
        mem_write_data  => mem_write_data,
        sp_out          => sp_value
    );

    -- ======================================================
    -- MEM/WB REGISTER
    -- ======================================================
    mem_wb_inst : mem_wb_register
    GENERIC MAP(WIDTH => 32)
    PORT MAP(
        clk => clk, reset => reset, stall => '0',
        wb_enable_in => wbe_ex2mem,
        output_sel   => osel_ex2mem,
        alu_mem_sel  => ams_ex2mem,
        read_data_in  => mem_read_data_out,
        alu_result_in => ar_ex2mem,
        wb_address_in => wba_ex2mem,
        wb_enable_out  => wbe_memwb,
        output_sel_out => osel_memwb,
        alu_mem_sel_out => ams_memwb,
        read_data_out  => rd_memwb,
        alu_result_out => ar_memwb,
        wb_address_out => wba_memwb
    );

    -- ======================================================
    -- WRITE-BACK STAGE
    -- ======================================================
    wb_inst : writeback_stage
    GENERIC MAP(DATA_WIDTH => 32)
    PORT MAP(
        output_sel    => osel_memwb,
        alu_mem_sel   => ams_memwb,
        alu_result    => ar_memwb,
        mem_read_data => rd_memwb,
        ccr_extended  => ccr_ext_wb,
        popped_PC     => popped_pc_wb,
        write_back_data => wb_data,
        output_port   => out_port_sig
    );

    -- ======================================================
    -- FORWARDING UNIT  (3 sources)
    -- ======================================================
    fu_inst : forwarding_unit
    PORT MAP(
        read_reg_1_addr => raddr1_idex,
        read_reg_2_addr => raddr2_idex,
        swap            => swap_idex,
        -- EX1/EX2 path (NEW)
        ex1_ex2_wb_addr   => wba_ex1ex2,
        ex1_ex2_wb_enable => wbe_ex1ex2,
        ex1_ex2_mem_read  => mrwe_ex1ex2(1),
        -- EX2/MEM path (was EX/MEM)
        ex2_mem_wb_addr   => wba_ex2mem,
        ex2_mem_wb_enable => wbe_ex2mem,
        ex2_mem_mem_read  => mrwe_ex2mem(1),
        -- MEM/WB path
        mem_wb_addr   => wba_memwb,
        mem_wb_enable => wbe_memwb,
        forward_a    => fu_fwd_a,
        forward_b    => fu_fwd_b,
        load_use_ex2 => fu_load_use_ex2,
        load_use_mem => fu_load_use_mem
    );

    -- ======================================================
    -- HAZARD CONTROL UNIT
    -- ======================================================
    hcu_inst : hazard_control_unit
    PORT MAP(
        load_use_ex2     => fu_load_use_ex2,
        load_use_mem     => fu_load_use_mem,
        mem_read_active  => mrwe_ex2mem(1),
        mem_write_active => mrwe_ex2mem(0),
        stall_pc         => hcu_stall_pc,
        stall_if_id      => hcu_stall_if_id,
        stall_id_ex1     => hcu_stall_id_ex1,
        flush_ex1_ex2    => hcu_flush_ex1ex2,
        pc_enable        => hcu_pc_enable,
        fetch_or_memory  => hcu_fetch_or_memory
    );

END ARCHITECTURE behavioral;
