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

add wave -divider "PC"
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

add wave -divider "Forwarding"
add wave sim:/processor/fu_fwd_a
add wave sim:/processor/fu_fwd_b

configure wave -namecolwidth 280
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1

force -freeze sim:/processor/clk 1 0, 0 {50 ns} -r 100ns
force -freeze sim:/processor/int     0
force -freeze sim:/processor/in_port 32'h00000000

force -freeze sim:/processor/reset 0
run 100ns
force -freeze sim:/processor/reset 1

# t=100: fetch 0xFF  IN R1 → 0x5
# t=200: fetch 0x100 IN R2 → 0x19
# t=300: fetch 0x101 IN R3 → 0xFFFFFFFF
# t=400: fetch 0x102 IN R4 → 0xFFFFF320

force -freeze sim:/processor/in_port 32'h00000005
run 100ns
force -freeze sim:/processor/in_port 32'h00000019
run 100ns
force -freeze sim:/processor/in_port 32'hFFFFFFFF
run 100ns
force -freeze sim:/processor/in_port 32'hFFFFF320
run 100ns
force -freeze sim:/processor/in_port 32'h00000000
run 3000ns

# Expected (zero-extend IADD):
#   R1 = 0x00000005
#   R2 = 0x00000005   (SWAP then ADD R2,R1,R2=0+5)
#   R3 = 0x00000005   (AND R3,R2,R6)
#   R4 = 0x00010018   (SWAP from R2 after IADD)
#   R5 = 0xFFFFFFFF   (MOV R3→R5 NOTE: old syntax, assembler encodes R3←R5=0)
#   R6 = 0x0001001F   (IADD R6,R6,2)
echo "TwoOperand complete."
echo "Expected: R3=5 R4=10018 R6=1001F"
