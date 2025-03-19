#! /usr/bin/bash

setup() {

	dependencies=("lsscsi")
	export dependencies
	
}

generate_logs() {

	# get date and time
	timestamp=$(date)
	# trim characters at the start
	timestamp="${timestamp:4}"
	# trim characters at the end
	timestamp="${timestamp::-4}"
	# replace spaces with underscores
	timestamp="${timestamp// /_}"
	# make variable timestamp available
	export timestamp
	
	# cli log
	
	# log file name
	log_file=log_$timestamp.txt
	# make log_file timestamp available
	export log_file
	# create log file
	sh -c 'touch $log_file'
	
	# system info
	
	# file name
	sysinfo_file=system-info_$timestamp.txt
	# make sysinfo_file available
	export sysinfo_file
	# create log file
	sh -c 'touch $log_file'

}

install_dependencies() {
	
	printf "\nInstalling dependencies...\n"
	
	for i in "${dependencies[@]}"
	do
		if dpkg -s "$i" &>/dev/null; then
			printf "\nPackage $i is present and won't be installed.\n\n"
	 	else
	 		printf "\nPackage $i is missing and will be installed.\n\n"
	 		apt-get install $i
		fi
	done
	
	printf "Dependencies OK.\n\n"

}

get_system_info() {
	
	printf "\n============================================================="
	printf "\nGeneral information\n"
	printf "=============================================================\n\n"
	lshw -short
	
	printf "\n============================================================="
	printf "\nDetailed information\n"
	printf "=============================================================\n\n"
	lshw
	
	printf "\n============================================================="
	printf "\nDisks\n"
	printf "=============================================================\n\n"
	fdisk -l
	
	printf "\n============================================================="
	printf "\nBlock devices\n"
	printf "=============================================================\n\n"
	lsblk -a
	
	printf "\n============================================================="
	printf "\nPCI devices\n"
	printf "=============================================================\n\n"
	lspci -v
	
	printf "\n============================================================="
	printf "\nSATA devices\n"
	printf "=============================================================\n\n"
	lsscsi -s
	
	printf "\n============================================================="
	printf "\nDMI table: System information\n"
	printf "=============================================================\n\n"
	dmidecode -t system
	
	printf "\n============================================================="
	printf "\nDMI table: CPU information\n"
	printf "=============================================================\n\n"
	dmidecode -t processor
	
	printf "\n============================================================="
	printf "\nDMI table: Memory information\n"
	printf "=============================================================\n\n"
	dmidecode -t memory
	
	printf "\n============================================================="
	printf "\nDMI table: BIOS information\n"
	printf "=============================================================\n\n"
	dmidecode -t bios
	
	printf "\n============================================================="
	printf "\nUSB devices\n"
	printf "=============================================================\n\n"
	lsusb -v

} >> $sysinfo_file

pause() {
	
	# print the message rather than including it on 'read' otherwise the message will always be on top instead of following the lines
	printf "\nPress any key to continue\n"
	read -n 1 -s -r -p ""

}

# watching for errors
trap 'error_handler $? $LINENO' ERR

error_handler() {
   
	echo "Error: ($1) occurred on $2"
	pause

}

step1() {
	printf "\nCleaning apt files"
	printf "\nsudo nrm -rf /var/lib/apt/lists/\n\n"
	# purge old apt configuration files
	rm -rf /var/lib/apt/lists/
}

step2() {
	printf "\nCleaning apt references"
	printf "\nsudo apt0get clean; sudo apt-get autoclean\n\n"
	# cleaning apt
	apt-get clean; sudo apt-get autoclean
}

step3() {
	printf "\nUpdating packages, trying to get missing data"
	printf "\nsudo apt-get update --fix-missing -y\n\n"
	# get fresh configuration files, resolve package conflicts
	apt-get update --fix-missing -y
}

step4() {
	printf "\nTrying to configure/install unpacked packages"
	printf "\nsudo dpkg --configure -a\n\n"
	# configure and install unpacked packages
	dpkg --force-all --configure -a
}

step5() {
	printf "\nInstall packages, trying to fix broken packages"
	printf "\nsudo apt-get --fix-broken install -f -y\n\n"
	apt-get --fix-broken --fix-missing install -f -y
}

step6() {
	printf "\nUpgrade packages, trying to fix broken and missing data"
	printf "\nsudo apt-get upgrade --fix-missing --fix-broken -y\n\n"
	apt-get upgrade --fix-missing --fix-broken -f -y
}

main() {

	setup

	printf "\nSystem information:\n"	
	uname -a
	printf "\n============================================================="
	printf "\n\nDebian Environment Maintenance Procedures  v0.1.0\n"
	printf "\nby Michel Castilho\n"
	printf "devmichelcastilho@gmail.com\n"
	printf "github.com/michelcastilho\n"
	printf "\nThis script attempts to fix many common issues by cleaning and regenerating package lists, unconfigured/unistalled packages and broken installs. You can check all attempts and their results in the log file and general information about your system on a separate file.\n"
	
	printf "\nBy proceeding, the following packages will be installed:\n\n"
	
	for i in "${dependencies[@]}"
	do
		if dpkg -s "$i" &>/dev/null; then
			printf ""
		else
			printf "$i\n"
		fi
	done
	
	printf "\n============================================================="
	
	printf "\n\nScript initiated\n"
	printf "\nLog saved to $log_file\n"
	printf "System information will be saved to $sysinfo_file\n"
	printf "\nPlease provide privileges to continue.\n"
	# elevate privileges
	[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"
	
	clear
	printf "\n============================================================="
	printf "\nMaintenance starting"
	printf "\n=============================================================\n\n"

	install_dependencies
	
	printf "\n\nSaving system information to $sysinfo_file...\n"
	get_system_info
	printf "System information saved to $sysinfo_file\n"
	
	step1
	step2
	step3
	step4
	step5
	step6
	
	printf "\n\nMaintenance finished. Log saved to $log_file"
	pause
	exit $?
}

generate_logs

main | tee -a $log_file

exit i
