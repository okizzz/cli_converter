#!/bin/bash

# First argument is path to directory which contain virtual machines

if [ $# -eq 0 ]
then
	echo "No path to directory provided!"
	exit 1
fi
VM_PATH=${1}
cd ${VM_PATH}

for vm in *
do
	printf "Registering VM ${vm}... "
	vboxmanage registervm ${VM_PATH}/${vm}/${vm}.vbox
	reg_result=$?
	if [ ${reg_result} -lt 1 ]
	then
		echo "OK"
	else
		echo "ERROR"
	fi
done
