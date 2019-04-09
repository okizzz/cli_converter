#!/bin/bash

registered_uuids=$(vboxmanage list vms | cut -d' ' -f2)
for uuid in ${registered_uuids}
do
	echo Unregistering VM UUID ${uuid}
	vboxmanage unregistervm ${uuid}
done
