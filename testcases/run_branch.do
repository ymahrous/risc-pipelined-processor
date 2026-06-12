# Run from: src/rtl/

do ../../testcases/compile_all.do

vsim -voptargs=+acc \
     -gMEM_FILE=./out.mem \
     work.processor

add wave -divider "Clock & Control"
add wave -color cyan                      sim:/processor/clk
add wave -color cyan                      sim:/processor/reset
add wave -color cyan                      sim:/processor/int
add wave -radix hexadecimal -color cyan   sim:/processor/in_port
add wave -radix hexadecimal -color cyan   sim:/processor/out_port

add wave -divider "PC & SP"
add wave -radix hexadecimal -color yellow sim:/processor/pc_out
add wave -radix hexadecimal -color yellow sim:/processor/sp_value
add wave -radix hexadecimal -color yellow sim:/processor/fetched_instruction

add wave -divider "Register File R0-R7"
add wave -radix hexadecimal -color green  sim:/processor/r0
add wave -radix hexadecimal -color green  sim:/processor/r1
add wave -radix hexadecimal -color green  sim:/processor/r2
add wave -radix hexadecimal -color green  sim:/processor/r3
add wave -radix hexadecimal -color green  sim:/processor/r4
add wave -radix hexadecimal -color green  sim:/processor/r5
add wave -radix hexadecimal -color green  sim:/processor/r6
add wave -radix hexadecimal -color green  sim:/processor/r7

add wave -divider "CCR"
add wave -radix hexadecimal -color blue   sim:/processor/ex1_ccr

add wave -divider "Branch"
add wave sim:/processor/ex2_jump_taken
add wave sim:/processor/cu_imm_jump_cs
add wave sim:/processor/cu_if_id_flush
add wave sim:/processor/cu_id_ex1_flush

add wave -divider "Hazard"
add wave sim:/processor/hcu_fetch_or_memory
add wave sim:/processor/fu_load_use_ex2
add wave sim:/processor/fu_load_use_mem

add wave -divider "Memory Bus"
add wave -radix hexadecimal -color orange sim:/processor/mem_address
add wave -radix hexadecimal -color orange sim:/processor/mem_write_data
add wave -radix hexadecimal -color orange sim:/processor/mem_read_data_out

configure wave -namecolwidth 280
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1

force -freeze sim:/processor/clk 1 0, 0 {50 ns} -r 100ns
force -freeze sim:/processor/int     0
force -freeze sim:/processor/in_port 32'h00000000

force -freeze sim:/processor/reset 0
run 100ns
force -freeze sim:/processor/reset 1

# t=100: IN R1 → 0x30
# t=200: IN R2 → 0x50
# t=300: IN R3 → 0x100
# t=400: IN R4 → 0x300

force -freeze sim:/processor/in_port 32'h00000030
run 100ns
force -freeze sim:/processor/in_port 32'h00000050
run 100ns
force -freeze sim:/processor/in_port 32'h00000100
run 100ns
force -freeze sim:/processor/in_port 32'h00000300
run 100ns
force -freeze sim:/processor/in_port 32'h00000000

# IN R1=0x60 at 0x054: after PUSH(1)+JMP(2+2flush)+AND+JZ(2+2flush)
# = 1+4+1+4 = 10 cycles from t=500ns → ~t=1500ns
# Wide window: drive at t=1300ns hold 400ns
run 800ns
force -freeze sim:/processor/in_port 32'h00000060
run 400ns
force -freeze sim:/processor/in_port 32'h00000000

# IN R1=0x70 at 0x060: after JZ-not-taken+more
# ~6 cycles after t=1700ns → t=2200ns
# Wide window: drive at t=2000ns hold 400ns
run 300ns
force -freeze sim:/processor/in_port 32'h00000070
run 400ns
force -freeze sim:/processor/in_port 32'h00000000

# IN R6=0x700 at 0x080: after JMP+IADD(2w)+SUB+PUSH+POP+JZ(2w+2flush)
# ~12 cycles after t=2400ns → t=3600ns
# Wide window: drive at t=3400ns hold 500ns
run 1000ns
force -freeze sim:/processor/in_port 32'h00000700
run 500ns
force -freeze sim:/processor/in_port 32'h00000000

# HW interrupt — optional, uncomment to test:
# Fire at ~t=5000ns (when INC R1 at 0x077 or POP R6 at 0x701 is active)
# force -freeze sim:/processor/int 1
# run 100ns
# force -freeze sim:/processor/int 0
# force -freeze sim:/processor/in_port 32'h00000005   ; R7=5 in handler
# run 300ns
# force -freeze sim:/processor/in_port 32'h00000000

run 12000ns

# Expected (no HW INT):
#   R1 = 0x000000D0   (ADD R1,R1,R2 = 0x80+0x50)
#   R2 = 0x00000050   (unchanged)
#   R3 = 0x00000100   (unchanged)
#   R4 = 0x00000300   (unchanged)
#   R5 = 0xFFFFFFFF   (NOT R5)
#   R6 = 0x00000401   (ADD R6,R3,R6=0x400, INC R6=0x401)
#   R7 = 0x00000080   (ADD R7,R0,R1)
#   SP = 0x00000FFF
#
# With HW INT (in_port=5 during handler):
#   R7 = 0x00000005   (IN R7 in handler)
#   OUT.PORT = 0x100  (OUT R3 in handler, R3=0x100)
echo "Branch complete. Expected: R1=D0 R6=401 R7=80 SP=FFF"
echo "With HW INT: R7=5 OUT=100"