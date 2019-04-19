import numpy
import sys
fp = open(sys.argv[1])
size_array = []
read_count = 0
write_count = 0
for line in fp:
    lines = line.rstrip().split(' ')
    access = int(lines[2])
    size_array.append(int(lines[3])*4096)
        

    if access>=0:
        write_count+=1
    else:
        read_count+=1
print 100*write_count/float(write_count+read_count), 100*read_count/float(write_count+read_count), numpy.average(size_array)
