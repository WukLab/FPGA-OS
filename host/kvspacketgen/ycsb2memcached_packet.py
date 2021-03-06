#!/usr/bin/env python3

import os
import sys, getopt
import copy

# Config
numofcharinkey = 14 # Don't change this one
valuelength = 2048     # length should not be larger than 256*256 and no less than 9

# global variable
out_dir = ''
mode = 'counter'

def combine_to_keylogs(filename1, filename2, filename3):
    filename1 = os.path.join(out_dir, filename1)
    filename2 = os.path.join(out_dir, filename2)
    filename3 = os.path.join(out_dir, filename3)
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

        # print(opcode, keylength, hexkey, key)
        # packet gen
        # 1
        unit1 = '00000008{0:02X}00{1:02X}80'.format(keylength, opcode)              # fixed term follow Xilinx testbench
        # 2
        if opcode == 0:
            unit2 = "00000000{0}".format(to_little_endian(0 + keylength))
        else:
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
                unit4 = "AA" * tempvaluelength
                tempvaluelength = 0
            unit4 = unit4.zfill(16)
        else:
            if tempkeylength >= 8:
                unit4 = hexkey[-16:]
                hexkey = hexkey[:-16]
                tempkeylength -= 8
            else:
                unit4 = hexkey[-(tempkeylength * 2):].zfill(16)
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
                    one_unit = hexkey[-16:]
                    hexkey = hexkey[:-16]
                    lengthused = 8
                    tempkeylength -= 8
                else:
                    one_unit = hexkey[-(keylength * 2):]
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
            # print(one_unit)

        # print(counter, lengthused)

        # output to file
        if mode == 'counter':
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
        elif mode == 'lastbyte':
            outputstr += add_packet_metadata_with_last(unit1, 8, False)
            outputstr += add_packet_metadata_with_last(unit2, 8, False)
            outputstr += add_packet_metadata_with_last(unit3, 8, False)
            if counter == 4:
                outputstr += add_packet_metadata_with_last(unit4, lengthused, True)
            else:
                outputstr += add_packet_metadata_with_last(unit4, 8, False)
                for unit in unit_rest:
                    if unit is unit_rest[-1]:
                        outputstr += add_packet_metadata_with_last(unit, lengthused, True)
                    else:
                        outputstr += add_packet_metadata_with_last(unit, 8, False)
        else:
            raise ValueError("Error Occurs: Error in parsering arguments")

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


def add_packet_metadata_with_last(unit, used, last):
    switcher = {
        1: '01', 2: '03', 3: '07', 4: '0F',
        5: '1F', 6: '3F', 7: '7F', 8: 'FF'
    }
    if not last:
        return "{0} {1} 0\n".format(unit, switcher.get(used))
    else:
        return "{0} {1} 1\n".format(unit, switcher.get(used))


def print_help():
    print('Usage: ./ycsb2memcached_packet.py -o <out_dir> [-m <mode>]')
    print()
    print('   -m <mode>  or --mode=<mode>    default to "counter"')
    print('      counter:  show counter before each packet')
    print('      lastbyte: indicate if each line is the end of packet with 1 or 0')


def main(argv):
    global out_dir
    global mode
    try:
        opts, _ = getopt.getopt(argv,"ho:m::",["out_dir=", "mode="])
        if not opts:
            print_help()
    except getopt.GetoptError:
        print_help()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print_help()
            sys.exit()
        elif opt in ("-o", "--out_dir"):
            out_dir = arg
        elif opt in ("-m", "--mode"):
            if arg in ('counter', 'lastbyte'):
                mode = arg
            else:
                print_help()

    out_dir = os.path.abspath(out_dir)


if __name__ == "__main__":
    main(sys.argv[1:])
    # combine_to_keylogs('ycsb_load.log', 'ycsb_run.log', 'ycsb_workload_keys.txt')
    # keylogs_to_packets('ycsb_workload_keys.txt', 'ycsb_workload_packets.txt')
    keylogs_to_packets('ycsb_load.log', 'load_packets.txt')
    keylogs_to_packets('ycsb_run.log', 'run_packets.txt')
