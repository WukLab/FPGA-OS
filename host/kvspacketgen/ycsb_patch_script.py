#!/usr/bin/env python3

import os
import sys, getopt

def main(argv):
    # parser input arguments
    ycsb_dir = ''
    out_dir = ''
    try:
        opts, _ = getopt.getopt(argv,"hd:o:",["ycsb_dir=","out_dir="])
        if not opts:
            print('Usage: ./ycsb_patch_script.py -d <ycsb_dir> -o <out_dir>')
    except getopt.GetoptError:
        print('Usage: ./ycsb_patch_script.py -d <ycsb_dir> -o <out_dir>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('Usage: ./ycsb_patch_script.py -d <ycsb_dir> -o <out_dir>')
            sys.exit()
        elif opt in ("-d", "--yscb_dir"):
            ycsb_dir = arg
        elif opt in ("-o", "--out_dir"):
            out_dir = arg

    # prepare file path
    ycsb_dir = os.path.abspath(ycsb_dir) + '/'
    out_dir = os.path.abspath(out_dir) + '/'
    cur_dir = os.getcwd()
    patchfilename = cur_dir + "/ycsb_output_key.patch"
    objectfilename = "memcached/src/main/java/com/yahoo/ycsb/db/MemcachedClient.java"

    # replace patch output path with arguments
    with open(patchfilename) as patch:
        patchstr = patch.read()
    patchstr = patchstr.replace("ycsb_load.log", out_dir + 'ycsb_load.log', 1)
    patchstr = patchstr.replace("ycsb_run.log", out_dir + 'ycsb_run.log', 1)

    # construct command and execute
    print("Patching Memcached File")
    cmd = "echo -n -E \'{0}\' | patch -d \'{1}\' \'{2}\' -i - -r -".format(patchstr, ycsb_dir, objectfilename)
    ret = os.system(cmd)
    if ret != 0:
        print("Patch Applied Failure, YCSB directory provided is wrong")
        sys.exit(-1)


if __name__ == "__main__":
    main(sys.argv[1:])

