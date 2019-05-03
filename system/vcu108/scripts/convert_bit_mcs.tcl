# Refer to Xilinx xtp366 VCU108 PCIe Design Tutorial

set input_file_name [lindex $argv 0]
set output_file_name [lindex $argv 1]
puts "Input File is $input_file_name"
puts "Output File is $output_file_name"

write_cfgmem -force -format MCS -size 128 -interface BPIx16 -loadbit "up 0x00000000 $input_file_name" $output_file_name

exit
