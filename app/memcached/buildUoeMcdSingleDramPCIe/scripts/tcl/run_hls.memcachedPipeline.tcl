open_project memcachedPipeline_prj

set_top memcachedPipeline

add_files ../../hls/sources/hashTable/cc.cpp
add_files ../../hls/sources/hashTable/compare.cpp
add_files ../../hls/sources/hashTable/hash.cpp
add_files ../../hls/sources/hashTable/hashTable.cpp
add_files ../../hls/sources/hashTable/memRead.cpp
add_files ../../hls/sources/hashTable/memWrite.cpp
add_files ../../hls/sources/requestParser/requestParser.cpp
add_files ../../hls/sources/responseFormatter/binResponse.cpp
add_files ../../hls/sources/valueStore/valueStore.cpp
add_files ../../hls/sources/valueStore/flashValueStore.cpp
add_files ../../hls/sources/globals.cpp
add_files ../../hls/sources/merger.cpp
add_files ../../hls/sources/splitter.cpp
add_files ../../hls/sources/memcachedPipeline.cpp
add_files -tb ../../hls/sources/memcachedPipeline_tb.cpp

open_solution "solution1"
set_part {xc7vx690tffg1157-2}
create_clock -period 6.66 -name default
config_rtl -reset all -reset_async

csynth_design
export_design -format ip_catalog -display_name "Combined Binary Flash/DRAM Memcached Pipeline" -description "A 4 stage memcached pipeline with SSD & DRAM value stores supporting only the binary protocol" -vendor "xilinx.labs" -version "1.07"
exit
