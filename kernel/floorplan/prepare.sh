#!/bin/bash

opcode=$1
nr_modules=$2
module_name=$3

from="src/base_rp_module"
to="generated_modules/$3"

if [ "$#" -ne 3 ]; then
	echo "Usage: ./script.sh OPCODE NR_MODULES MODULE_PREFIX"
	exit
fi

#
# Generate multiple dummy RP module directories
# and copy the template code into them.
#
for ((i = 0; i < $nr_modules; i++))
do
	if [ $opcode == "1" ]; then
		mkdir -p ${to}_${i}
		cp -r ${from}/* ${to}_${i}
	elif [ $opcode == "2" ]; then
		rm -rf ${to}_${i}
	fi
done
