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

configure wave -namecolwidth 280
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1

force -freeze sim:/processor/clk 1 0, 0 {50 ns} -r 100ns
force -freeze sim:/processor/int     0
force -freeze sim:/processor/in_port 32'h00000000

force -freeze sim:/processor/reset 0
run 100ns
force -freeze sim:/processor/reset 1

# Program at 0xA0: NOP NOT INC IN IN NOT INC OUT OUT SETC INC OUT HLT
# t=100: fetch 0xA0 NOP
# t=200: fetch 0xA1 NOT
# t=300: fetch 0xA2 INC
# t=400: fetch 0xA3 IN R1 → drive 0x5
# t=500: fetch 0xA4 IN R2 → drive 0x10

run 300ns
force -freeze sim:/processor/in_port 32'h00000005
run 100ns
force -freeze sim:/processor/in_port 32'h00000010
run 100ns
force -freeze sim:/processor/in_port 32'h00000000
run 2000ns

# Expected:
#   R1 = 0x00000006   (INC after IN)
#   R2 = 0xFFFFFFF0   (INC after NOT)
#   OUT.PORT sequence: 0x6 → 0xFFFFFFEF → 0xFFFFFFF0
#   CCR final: C=1 (SETC), N=1, Z=0 (after last INC R2)
echo "OneOperand complete. Expected: R1=6 R2=FFFFFFF0 OUT=FFFFFFF0 C=1 N=1 Z=0"
