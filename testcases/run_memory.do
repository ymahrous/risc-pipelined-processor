# Run from: src/rtl/

do ../../testcases/compile_all.do

vsim -voptargs=+acc \
     -gMEM_FILE=./out.mem \
     work.processor

add wave -divider "Clock & Control"
add wave -color cyan                      sim:/processor/clk
add wave -color cyan                      sim:/processor/reset
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

add wave -divider "Memory Bus"
add wave -radix hexadecimal -color orange sim:/processor/mem_address
add wave -radix hexadecimal -color orange sim:/processor/mem_write_data
add wave -radix hexadecimal -color orange sim:/processor/mem_read_data_out

add wave -divider "Hazard"
add wave sim:/processor/hcu_fetch_or_memory
add wave sim:/processor/fu_load_use_ex2
add wave sim:/processor/fu_load_use_mem

configure wave -namecolwidth 280
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1

force -freeze sim:/processor/clk 1 0, 0 {50 ns} -r 100ns
force -freeze sim:/processor/int     0
force -freeze sim:/processor/in_port 32'h00000000

force -freeze sim:/processor/reset 0
run 100ns
force -freeze sim:/processor/reset 1

# Program starts at 0x300:
# 0x300: IN R2   ← t=100ns → drive 0x19
# 0x301: IN R3   ← t=200ns → drive 0xFFFFFFFF
# 0x302: IN R4   ← t=300ns → drive 0xFFFFF320
# 0x303: LDM R1  (2-word: 0x303 + 0x304)
# 0x305: PUSH R1
# 0x306: PUSH R2
# 0x307: POP R1
# 0x308: POP R2
# 0x309: ADD R5
# 0x30A: IN R5   ← after ADD, fetch at t=100+(10)*100=1100ns
#         (3 IN + 2-word LDM + PUSH+PUSH+POP+POP+ADD = 10 word-fetches
#          but PUSH/POP each add 1 structural stall)
#         More carefully: each mem op adds 1 stall
#         Stalls: LDM(imm stall)+PUSH+PUSH+POP+POP = 5 stalls = 5 extra cycles
#         fetch cycles: 3 IN + 2(LDM) + 1+1+1+1+1(PUSH×2 POP×2 ADD) = 10
#         total: (10+5)*100 = 1500ns + 100ns reset = t=1600ns for IN R5
#         Use wide window: drive at t=1400ns, hold 400ns

run 100ns
# t=200: IN R2
force -freeze sim:/processor/in_port 32'h00000019
run 100ns
# t=300: IN R3
force -freeze sim:/processor/in_port 32'hFFFFFFFF
run 100ns
# t=400: IN R4
force -freeze sim:/processor/in_port 32'hFFFFF320
run 100ns
force -freeze sim:/processor/in_port 32'h00000000

# Wait for IN R5 window
run 900ns
# t=1400ns: drive 0x10 for IN R5 at 0x30A
force -freeze sim:/processor/in_port 32'h00000010
run 400ns
# t=1800ns: clear
force -freeze sim:/processor/in_port 32'h00000000

# IN R5 again at 0x314 and IN R2 at 0x315
# After IN R5 at 0x30A: STD(2w)+STD(2w)+LDD(2w)+LDD(2w)+ADD = 9 words + 5 stalls
# = 14 cycles from t=1800ns → t=1800+1400=3200ns
# Use wide window: drive at t=3000ns
run 1200ns
# t=3000ns: drive 0x10 for second IN R5 at 0x314
force -freeze sim:/processor/in_port 32'h00000010
run 100ns
# t=3100ns: drive 0x19 for IN R2 at 0x315
force -freeze sim:/processor/in_port 32'h00000019
run 200ns
force -freeze sim:/processor/in_port 32'h00000000

# Run to completion
run 6000ns

# Expected final state:
#   R1 = 0x00000019   (POP R1)
#   R2 = 0x0000001E   (ADD R2,R2,R3 = 5+19)
#   R3 = 0x00000019   (LDD R3,201(R5))
#   R4 = 0x00000005   (LDD R4,200(R5) / LDD R2,200(R3) sequence)
#   R5 = 0x00000010   (second IN R5)
#   SP = 0x00000FFF   (restored after 2 PUSH + 2 POP)
echo "Memory complete. Expected: R1=19 R2=1E R3=19 R4=5 SP=FFF"
