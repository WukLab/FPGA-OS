# HOWTO convert YCSB workload to xilinx memcached compatible packet files

## 1. install YCSB and memcached

See [YCSB official documents](https://github.com/brianfrankcooper/YCSB/tree/master/memcached) for details

## 2. modify memcached java file

execute script to modify ycsb memcached client (**in this directory**)

    ./packet_gen.py -d <ycsb_dir> -o <output_dir>

then recompile the memcached client, skip style check in case output file name is too long (**in YCSB directory**)

    mvn -Dcheckstyle.skip -pl com.yahoo.ycsb:memcached-binding -am clean package

## 3. run memcached to get packet files

open another console, simply execute `memcached` to start memcached server. With existing workload config in `YCSB/workloads` or your own config execute commands below:

Load the data:

    ./bin/ycsb load memcached -s -P workloads/workloada > /dev/null

Run the workload test:

    ./bin/ycsb run memcached -s -P workloads/workloada > /dev/null

after these two commands, you should see two files named `ycsb_load.log` and `ycsb_run.log` existed in the directory you specified above

Now run key files to packet file conversion scripts to get packet files

    ./ycsb2memcached_packet.py -o <output_dir>

The output directory should be same as above. Otherwise, the script cannot find files that contain YCSB keys

## 4. Packet Files

Here is the file you finally get

    ycsb_workload_packets.txt

You should expect something like below

    7
    0000000816000180 FF
    0000000020000000 FF
    0000000000000000 FF
    AAAAAAAAAAAAAAAA FF
    757365727461626C FF
    652D757365725738 FF
    AAAA07CDD7E5C63B FF

The first line is number of packet. The first column of rest of lines contains packet data. The second column of rest of lines contains `keep` *(how many bytes are valid)*