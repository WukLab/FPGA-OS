import os
import sys

NR_SET = 12
NR_GET = 12

with open(os.path.join(sys.path[0], "input.txt"), "w") as file:
    for k in range(NR_SET):
        file.write("0\n")
        address = 0x400 * (k + 1)
        length = 0x66666660 + k
        opcode = 2
        line = "{:0=2x}{:0=8x}{:0=8x}".format(opcode, length, address)
        print(line)
        print("SET [{:x}, {:x}]".format(address, length))
        file.write(line + '\n')

    for j in range(NR_GET):
        file.write("0\n")
        address = 0x400 * (j + 1)
        length = 0
        if j % 2:
            opcode = 0
        else:
            opcode = 1
        line = "{:0=2x}{:0=8x}{:0=8x}".format(opcode, length, address)
        print(line)
        print("GET {:x}".format(address))
        file.write(line + '\n')
