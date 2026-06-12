#!/usr/bin/env python3
"""
python assembler.py input.asm output.mem
"""
import sys
import re
import argparse

MAX_ADDR   = 0xFFF   # 4 KB – 1
MAX_WORDS  = MAX_ADDR + 1  # 4096

OPCODES = {
    'NOP':  0b00000,
    'HLT':  0b00001,
    'SETC': 0b00010,
    'NOT':  0b00011,
    'INC':  0b00100,
    'OUT':  0b00101,
    'IN':   0b00110,
    'MOV':  0b01000,
    'SWAP': 0b01001,
    'ADD':  0b01010,
    'SUB':  0b01011,
    'AND':  0b01100,
    'PUSH': 0b10000,
    'POP':  0b10001,
    'LDM':  0b10100,
    'LDD':  0b10101,
    'STD':  0b10110,
    'IADD': 0b10111,
    'JZ':   0b11000,
    'JN':   0b11001,
    'JC':   0b11010,
    'JMP':  0b11011,
    'CALL': 0b11100,
    'RET':  0b11101,
    'INT':  0b11110,
    'RTI':  0b11111,
}

REGISTER_RE = re.compile(r'R([0-7])$', re.IGNORECASE)

def parse_reg(token):
    m = REGISTER_RE.match(token.strip().upper())
    if not m:
        raise ValueError(f"Invalid register '{token}' (must be R0–R7)")
    return int(m.group(1))


def parse_int(token):
    return int(token.strip(), 16)


def preprocess(lines):
    cleaned = []
    for line_num, line in enumerate(lines, start=1):
        line = re.sub(r';.*$',  '', line)
        line = re.sub(r'#.*$',  '', line)
        line = re.sub(r'//.*$', '', line)
        line = re.sub(r'\bINT([0-3])\b', r'INT \1', line, flags=re.IGNORECASE)
        line = line.strip()
        if line:
            cleaned.append((line_num, line))
    return cleaned


def assemble(cleaned):
    mem = {}
    current_address = 0
    for line_num, line in cleaned:
        try:
            # .ORG
            if line.upper().startswith(".ORG"):
                parts = line.split()
                if len(parts) != 2:
                    raise ValueError("Usage: .ORG <hex_address>")
                current_address = parse_int(parts[1])
                if current_address > MAX_ADDR:
                    print(f"WARNING line {line_num}: .ORG 0x{current_address:X} "
                          f"exceeds 4 KB address space (max 0x{MAX_ADDR:X})",
                          file=sys.stderr)
                continue

            # Raw hex data word
            if re.match(r'^(0x)?[0-9A-Fa-f]+$', line):
                val = parse_int(line)
                mem[current_address] = val & 0xFFFFFFFF
                current_address += 1
                continue

            # instruction
            words = assemble_one(line)
            for w in words:
                if current_address > MAX_ADDR:
                    print(f"WARNING line {line_num}: address 0x{current_address:X} "
                          f"exceeds 4 KB address space", file=sys.stderr)
                mem[current_address] = w
                current_address += 1

        except Exception as e:
            raise Exception(f"Line {line_num}: {e}")

    return mem


def assemble_one(line):
    parts = [p for p in re.split(r"[,\s]+", line) if p]
    mnem  = parts[0].upper()
    args  = parts[1:]

    if mnem not in OPCODES:
        raise ValueError(f"Unknown instruction '{mnem}'")

    opcode = OPCODES[mnem]
    rsrc1 = rsrc2 = rdst = index = 0
    imm_needed = False
    imm_value  = 0

    if mnem in ("NOP", "HLT", "SETC", "RET", "RTI"):
        pass

    elif mnem in ("NOT", "INC", "IN"):
        # Rdst [20:18]
        rdst = parse_reg(args[0])

    elif mnem == "OUT":
        # Rsrc1 [26:24]
        rsrc1 = parse_reg(args[0])

    elif mnem == "MOV":
        # MOV Rdst, Rsrc
        rdst  = parse_reg(args[0])
        rsrc1 = parse_reg(args[1])

    elif mnem == "SWAP":
        # SWAP Rdst, Rsrc
        rdst  = parse_reg(args[0])
        rsrc1 = parse_reg(args[1])

    elif mnem == "PUSH":
        # Rsrc1 [26:24]
        rsrc1 = parse_reg(args[0])

    elif mnem == "POP":
        # Rdst [20:18]
        rdst = parse_reg(args[0])

    elif mnem in ("ADD", "SUB", "AND"):
        rdst  = parse_reg(args[0])
        rsrc1 = parse_reg(args[1])
        rsrc2 = parse_reg(args[2])

    elif mnem == "IADD":
        rdst  = parse_reg(args[0])
        rsrc1 = parse_reg(args[1])
        try:
            imm_value  = parse_int(args[2])
            imm_needed = True
        except ValueError:
            # no immediate word
            rsrc2      = parse_reg(args[2])
            imm_needed = False

    elif mnem == "LDM":
        rdst       = parse_reg(args[0])
        imm_value  = parse_int(args[1])
        imm_needed = True

    elif mnem == "LDD":
        rdst = parse_reg(args[0])
        m = re.match(r"^(.+)\((R[0-7])\)$", args[1], re.IGNORECASE)
        if not m:
            raise ValueError(f"Invalid LDD syntax: expected offset(Rn), got '{args[1]}'")
        offset_tok, reg_tok = m.groups()
        rsrc1      = parse_reg(reg_tok)
        imm_value  = parse_int(offset_tok)
        imm_needed = True

    elif mnem == "STD":
        # STD Rsrc1, offset(Rsrc2)
        rsrc2 = parse_reg(args[0])
        m = re.match(r"^(.+)\((R[0-7])\)$", args[1], re.IGNORECASE)
        if not m:
            raise ValueError(f"Invalid STD syntax: expected offset(Rn), got '{args[1]}'")
        offset_tok, reg_tok = m.groups()
        rsrc1      = parse_reg(reg_tok)
        imm_value  = parse_int(offset_tok)
        imm_needed = True

    elif mnem in ("JZ", "JN", "JC", "JMP", "CALL"):
        imm_value  = parse_int(args[0])
        imm_needed = True

    elif mnem == "INT":
        index = parse_int(args[0]) & 0b11

    word  = 0
    word |= (opcode & 0x1F) << 27
    word |= (rsrc1  & 0x07) << 24
    word |= (rsrc2  & 0x07) << 21
    word |= (rdst   & 0x07) << 18
    word |= (index  & 0x03) << 16

    out = [word & 0xFFFFFFFF]
    if imm_needed:
        out.append(imm_value & 0xFFFFFFFF)

    return out


def write_mem(mem, path):
    if not mem:
        max_addr = 0
    else:
        max_addr = min(max(mem.keys()), MAX_ADDR)

    with open(path, "w") as f:
        for addr in range(max_addr + 1):
            val = mem.get(addr, 0)
            f.write(f"{val:032b}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Assembler for CMPS 301 new 6-stage processor ISA")
    parser.add_argument("input",  help="input .asm file")
    parser.add_argument("output", help="output .mem file")
    a = parser.parse_args()

    with open(a.input, "r") as f:
        lines = f.readlines()

    cleaned  = preprocess(lines)
    mem_dict = assemble(cleaned)
    write_mem(mem_dict, a.output)

    hi = max(mem_dict.keys()) if mem_dict else 0
    print(f"Assembled {len(mem_dict)} words, highest address 0x{hi:03X} → {a.output}")


if __name__ == "__main__":
    main()