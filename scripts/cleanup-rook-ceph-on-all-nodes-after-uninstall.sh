#!/bin/bash

# Before executing this script,
# You'd better check the page which describe how to clean up the cluster:
#   https://github.com/rook/rook/blob/release-1.6/Documentation/ceph-teardown.md



if [ "$#" -eq 0 ]
then
	echo "usage: $0 <node-1-host> <node-2-host> ..."
	exit 1
fi



for NODE in $@
do
	echo
	echo "Accessing node \"$NODE\"..."
	ssh -t "$NODE" bash -c 'true

	sudo true
	if [ "$?" -ne 0 ]; then	echo; exit; fi
	echo



	# /var/lib/rook
	if [ -d "/var/lib/rook" ]
	then
		echo "Cleaning \"/var/lib/rook\"..."
		sudo rm -rf "/var/lib/rook"
	fi



	# /dev/mapper/ceph--*
	for f in /dev/mapper/ceph--*
	do
		if [ ! -e "$f" ]; then continue; fi
		echo "Cleaning \"$f\"..."
		sudo dmsetup remove "$f"
		sudo rm -rf "$f"
	done



	# /dev/ceph-*
	for f in /dev/ceph-*
	do
		if [ ! -e "$f" ]; then continue; fi
		echo "Cleaning \"$f\"..."
		sudo rm -rf "$f"
	done

	' # END OF SSH BASH -C

done
