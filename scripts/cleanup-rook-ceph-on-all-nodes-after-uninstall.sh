#!/bin/bash

# Before executing this script,
# You'd better check the page which describe how to clean up the cluster:
#   https://github.com/rook/rook/blob/release-1.6/Documentation/ceph-teardown.md



if [ "$#" -eq 0 ]
then
	echo "usage: $0 <node-1-host> <node-2-host> ..."
	exit 1
fi




# confirm wipe
echo " ***** CAUTION ***** "
echo "  - On the given hosts: $@"
echo "    This script automatically deletes/wipe followings without prompt:"
echo "    - /var/lib/rook"
echo "    - /dev/mapper/ceph--*"
echo "    - /dev/ceph-*"
echo "    - And all existing cephfs partitions (ceph_bluestore)"
echo
echo "    (For more information about the cleanup process :"
echo "      https://github.com/rook/rook/blob/release-1.6/Documentation/ceph-teardown.md )"
echo
echo "    It is highly recommended that you run these commands manually,"
echo "    if there are important data in the target hosts."
echo

echo -n "DO YOU REALLY WANT TO WIPE ALL ABOVE AUTOMATICALLY? [y/n]: "
read CONFIRM
if [ "$CONFIRM" != "Y" ] && [ "$CONFIRM" != "y" ]
then
	echo "Cleanup is cancelled by user."
	exit 1
fi




# repeat cleanup with all hosts
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



	# wipe all ceph_bluestore fs
	CEPHFS_LIST=$(lsblk --path -rno NAME,FSTYPE | grep " ceph_bluestore$" | cut -d" " -f1)
	for cephfs in $CEPHFS_LIST
	do
		echo "Wiping cephfs \"$cephfs\"..."
		sudo wipefs -a $cephfs
	done

	' # END OF SSH BASH -C

done
