import copy

# Config
numofcharinkey = 14
valuelength = 100  #length should not be larger than 256*256

def combine_to_keylogs(filename1, filename2, filename3):
    with open(filename1, 'r') as file1:
        str1 = file1.read()

    with open(filename2, 'r') as file2:
        str2 = file2.read()

    with open(filename3, 'w') as file3:
        str3 = str1 + str2
        file3.write(str3)

def keylogs_to_packets(filename1, filename2):
    with open(filename1, 'r') as file1:
        requests = file1.read().splitlines()

    outputstr = str()
    for req in requests:
        opcode, key = req.split(',', 2)
        opcode = int(opcode)
        key.encode('ascii')
        hexkey = "".join("{:02X}".format(ord(c)) for c in key[:numofcharinkey])     # this part is character
        hexkey += hex(int(key[numofcharinkey:]))[2:]                                # this part is number
        keylength = len(hexkey) // 2 + len(hexkey) % 2                              # each hex is 4 bits, length is in terms of byte
        hexkey = hexkey.zfill(keylength * 2).upper()

        print(opcode, keylength, hexkey, key)
        # packet gen
        # 1
        unit1 = '00000008{0:02X}00{1:02X}80'.format(keylength, opcode)              # fixed term follow Xilinx testbench
        # 2
        unit2 = "00000000{0}".format(to_little_endian(valuelength + keylength))
        # 3
        unit3 = "00" * 8
        # 4
        tempkeylength = keylength
        if opcode == 1:
            tempvaluelength = valuelength
        else:
            tempvaluelength = 0
        if opcode == 1:     # if it's a update/insert operation
            if tempvaluelength >= 8:
                unit4 = "AA" * 8
                tempvaluelength -= 8
            else:
                unit4 = "{0}{1}".format("00" * (8-tempvaluelength), "AA" * tempvaluelength)
                tempvaluelength = 0
        else:
            if tempkeylength >= 8:
                unit4 = hexkey[:16]
                hexkey = hexkey[16:]
                tempkeylength -= 8
            else:
                unit4 = hexkey[:tempkeylength * 2].zfill(16)
                lengthused = tempkeylength
                tempkeylength = 0

        # print(unit1, unit2, unit3, unit4)
        # rest
        counter = 4
        unit_rest = []
        while (tempvaluelength > 0 or tempkeylength > 0):
            lengthused = 0
            counter += 1
            one_unit = ''

            # deal with key
            if tempkeylength > 0:
                if tempkeylength >= 8:
                    one_unit = hexkey[:16]
                    hexkey = hexkey[16:]
                    lengthused = 8
                    tempkeylength -= 8
                else:
                    one_unit = hexkey[:keylength * 2]
                    lengthused = tempkeylength
                    tempkeylength = 0

            #deal with value
            if tempvaluelength > 0 and lengthused < 8:
                lengthleft = 8 - lengthused
                if tempvaluelength >= lengthleft:
                    one_unit = "{0}{1}".format("AA" * lengthleft, one_unit)
                    lengthused += lengthleft
                    tempvaluelength -= lengthleft
                else:
                    one_unit = "{0}{1}".format("AA" * tempvaluelength, one_unit)
                    lengthused += tempvaluelength
                    tempvaluelength = 0

            one_unit = one_unit.zfill(16)                   # pad to 8 bytes with 0
            unit_rest.append(copy.deepcopy(one_unit))
            print(one_unit)

        print(counter, lengthused)

        # output to file
        outputstr += '{0}\n'.format(counter)
        outputstr += add_packet_metadata(unit1, 8)
        outputstr += add_packet_metadata(unit2, 8)
        outputstr += add_packet_metadata(unit3, 8)
        if counter == 4:
            outputstr += add_packet_metadata(unit4, lengthused)
        else:
            outputstr += add_packet_metadata(unit4, 8)
            for unit in unit_rest:
                if unit is unit_rest[-1]:
                    outputstr += add_packet_metadata(unit, lengthused)
                else:
                    outputstr += add_packet_metadata(unit, 8)

    with open(filename2, 'w') as file2:
        file2.write(outputstr)




def to_little_endian(valuelength):
    temp = '{:08X}'.format(valuelength)
    return '' + temp[6:] + temp[4:6] + temp[2:4] + temp[:2]


def add_packet_metadata(unit, used):
    switcher = {
        1: '01', 2: '03', 3: '07', 4: '0F',
        5: '1F', 6: '3F', 7: '7F', 8: 'FF'
    }
    return "{0} {1}\n".format(unit, switcher.get(used))



if __name__ == "__main__":
    # combine_to_keylogs('keylogs1.txt', 'keylogs2.txt', 'yscb_workloada.txt')
    keylogs_to_packets('yscb_workloada.txt', 'testing.txt')