# Run from src/rtl/

set RTL        "."
set COMP       "$RTL/components"
set CU         "$RTL/control_unit/src"
set PREGS      "$RTL/pipeline_registers/src"
set FETCH      "$RTL/stages/1-fetch/src"
set DECODE     "$RTL/stages/2-decode/src"
set EX1        "$RTL/stages/3-execute1/src"
set EX2        "$RTL/stages/4-execute2/src"
set MEM        "$RTL/stages/5-memory/src"
set WB         "$RTL/stages/6-writeback/src"

vlib work
vmap work work

echo "Compiling primitives..."
vcom -2008 -work work $COMP/dff.vhd
vcom -2008 -work work $COMP/mux_2to1.vhd
vcom -2008 -work work $COMP/mux_4to1.vhd
vcom -2008 -work work $COMP/demux_1to4.vhd

echo "Compiling ALU & CCR..."
vcom -2008 -work work $COMP/alu.vhd
vcom -2008 -work work $COMP/ccr.vhd

echo "Compiling register file, PC, SP..."
vcom -2008 -work work $COMP/register_file.vhd
vcom -2008 -work work $COMP/pc.vhd
vcom -2008 -work work $COMP/sp_unit.vhd

echo "Compiling memory & hazard components..."
vcom -2008 -work work $COMP/memory.vhd
vcom -2008 -work work $COMP/imm_detect.vhd
vcom -2008 -work work $COMP/jump_detection_unit.vhd
vcom -2008 -work work $COMP/forwarding_unit.vhd
vcom -2008 -work work $COMP/hazard_control_unit.vhd

echo "Compiling control unit..."
vcom -2008 -work work $CU/control_unit.vhd

echo "Compiling pipeline registers..."
vcom -2008 -work work $PREGS/if_id_register.vhd
vcom -2008 -work work $PREGS/id_ex1_register.vhd
vcom -2008 -work work $PREGS/ex1_ex2_register.vhd
vcom -2008 -work work $PREGS/ex2_mem_register.vhd
vcom -2008 -work work $PREGS/mem_wb_register.vhd

echo "Compiling fetch stage..."
vcom -2008 -work work $FETCH/fetch_stage.vhd

echo "Compiling decode stage..."
vcom -2008 -work work $DECODE/decode.vhd

echo "Compiling execute stages..."
vcom -2008 -work work $EX1/execute1_stage.vhd
vcom -2008 -work work $EX2/execute2_stage.vhd

echo "Compiling memory stage..."
vcom -2008 -work work $MEM/memory_wrapper.vhd
vcom -2008 -work work $MEM/memory_stage.vhd

echo "Compiling writeback stage..."
vcom -2008 -work work $WB/writeback_stage.vhd

echo "Compiling top-level processor..."
vcom -2008 -work work $RTL/processor.vhd

echo "Compilation complete."