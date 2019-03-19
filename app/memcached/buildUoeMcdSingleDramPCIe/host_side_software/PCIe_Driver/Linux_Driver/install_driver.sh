#performs all steps needed to get a driver up and running
#Same as laid out in README
#needs root to work
#If it does not work, look at the README and perform the steps by hand

if [[ $EUID -ne 0 ]]; then
	echo "this script must be run as root"
	exit 1
fi

make
./make_device
insmod xpcie.ko
