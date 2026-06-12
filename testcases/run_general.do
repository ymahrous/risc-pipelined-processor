#   do ../../testcases/run_general.do <mem_file> [run_time_ns]
#
# EXAMPLES:
#   do ../../testcases/run_general.do ../../programs/MyProgram.mem 50000
# =============================================================

set mem_file  [lindex $argv 0]
set run_time  [lindex $argv 1]

if { $mem_file eq "" } {
    echo "ERROR: No .mem file specified."
    echo "Usage: do run_general.do <mem_file> \[run_time_ns\]"
    echo "Example: do ../../testcases/run_general.do ../../testcases/Memory.mem 8000"
    return
}

if { $run_time eq "" } {
    set run_time 20000
}

echo "----------------------------------------"
echo "  Program : $mem_file"
echo "  Run time: ${run_time}ns"
echo "----------------------------------------"

do ../../testcases/compile_all.do
vsim -voptargs=+acc \
     -gMEM_FILE=$mem_file \
     work.processor

# ── Step 3: Waves ──────────────────────────────────────────
add wave -divider "Clock & Control"
add wave -color cyan                       sim:/processor/clk
add wave -color cyan                       sim:/processor/reset
add wave -color cyan                       sim:/processor/int
add wave -radix hexadecimal -color cyan    sim:/processor/in_port
add wave -radix hexadecimal -color cyan    sim:/processor/out_port

add wave -divider "PC & SP"
add wave -radix hexadecimal -color yellow  sim:/processor/pc_out
add wave -radix hexadecimal -color yellow  sim:/processor/sp_value
add wave -radix hexadecimal -color yellow  sim:/processor/fetched_instruction

add wave -divider "Register File R0-R7"
add wave -radix hexadecimal -color green   sim:/processor/r0
add wave -radix hexadecimal -color green   sim:/processor/r1
add wave -radix hexadecimal -color green   sim:/processor/r2
add wave -radix hexadecimal -color green   sim:/processor/r3
add wave -radix hexadecimal -color green   sim:/processor/r4
add wave -radix hexadecimal -color green   sim:/processor/r5
add wave -radix hexadecimal -color green   sim:/processor/r6
add wave -radix hexadecimal -color green   sim:/processor/r7

add wave -divider "CCR Flags"
add wave -radix hexadecimal -color blue    sim:/processor/ex1_ccr

add wave -divider "Pipeline: IF/ID"
add wave -radix hexadecimal               sim:/processor/next_pc_if_id
add wave -radix hexadecimal               sim:/processor/inst_out_if_id

add wave -divider "Pipeline: EX1"
add wave -radix hexadecimal -color magenta sim:/processor/ex1_alu_result
add wave -radix hexadecimal -color magenta sim:/processor/rd1_idex
add wave -radix hexadecimal -color magenta sim:/processor/rd2_idex

add wave -divider "Pipeline: EX1/EX2"
add wave -radix hexadecimal -color magenta sim:/processor/ar_ex1ex2
add wave -radix hexadecimal -color magenta sim:/processor/ccr_ex1ex2

add wave -divider "Pipeline: EX2/MEM"
add wave -radix hexadecimal -color orange  sim:/processor/ar_ex2mem
add wave -radix hexadecimal -color orange  sim:/processor/mem_address
add wave -radix hexadecimal -color orange  sim:/processor/mem_write_data
add wave -radix hexadecimal -color orange  sim:/processor/mem_read_data_out

add wave -divider "Pipeline: MEM/WB"
add wave -radix hexadecimal               sim:/processor/wbe_memwb
add wave -radix hexadecimal               sim:/processor/wba_memwb
add wave -radix hexadecimal               sim:/processor/ar_memwb
add wave -radix hexadecimal               sim:/processor/rd_memwb

add wave -divider "Hazard & Forwarding"
add wave                                   sim:/processor/fu_fwd_a
add wave                                   sim:/processor/fu_fwd_b
add wave                                   sim:/processor/fu_load_use_ex2
add wave                                   sim:/processor/fu_load_use_mem
add wave                                   sim:/processor/hcu_fetch_or_memory
add wave                                   sim:/processor/hcu_stall_pc
add wave                                   sim:/processor/hcu_flush_ex1ex2

add wave -divider "Branch"
add wave                                   sim:/processor/ex2_jump_taken
add wave                                   sim:/processor/cu_imm_jump_cs
add wave                                   sim:/processor/cu_if_id_flush
add wave                                   sim:/processor/cu_id_ex1_flush

configure wave -namecolwidth 300
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -rowmargin 4
configure wave -childrowmargin 2

force -freeze sim:/processor/clk 1 0, 0 {50 ns} -r 100ns
force -freeze sim:/processor/int     0
force -freeze sim:/processor/in_port 32'h00000000

force -freeze sim:/processor/reset 0
run 100ns
force -freeze sim:/processor/reset 1

run ${run_time}ns

echo "----------------------------------------"
echo "  Simulation complete: $mem_file"
echo "  Time elapsed: [expr 100 + $run_time]ns total"
echo "----------------------------------------"