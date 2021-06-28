#!/bin/bash

# Rook Ceph - Shared Storage
# More info: https://github.com/rook/rook
GIT_BRANCH=release-1.6
YAML_BASE_URL="https://raw.githubusercontent.com/rook/rook/$GIT_BRANCH/cluster/examples/kubernetes/ceph/"



# check arg
if ! [ "$1" = "install" -a "$#" = "2" ] && ! [ "$1" = "uninstall" -a "$#" = "1" ]
then
	echo "usage: $0 <mode> [args]"
	echo
	echo "          <mode>: [ install | uninstall ]"
	echo
	echo "                  install <mon-counts>"
	echo "                          ( <mon-counts> <= (worker node counts) )"
	echo
	echo "                  uninstall"
	echo
	exit 1
fi



# install mode
if [ "$1" = "install" ]
then


	# get mon counts. if less than 1 or NaN, then set to 1
	MON_COUNTS="$2"
	if ! [ "$2" -ge 1 ] 2> /dev/null
	then
		MON_COUNTS="1"
	fi
	MON_COUNTS_YAML="
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  mon:
    count: $MON_COUNTS
"



	# install yaml
	kubectl create -f "$YAML_BASE_URL"/common.yaml && \
	kubectl create -f "$YAML_BASE_URL"/operator.yaml && \
	kubectl create -f "$YAML_BASE_URL"/crds.yaml && \
	kubectl create -f "$YAML_BASE_URL"/cluster.yaml && \
	echo "$MON_COUNTS_YAML" | kubectl apply -f- && \
	kubectl create -f "$YAML_BASE_URL"/filesystem.yaml && \
	kubectl create -f "$YAML_BASE_URL"/csi/cephfs/storageclass.yaml
	EXIT_CODE=$?



	# watch for osd running
	if [ "$EXIT_CODE" -eq 0 ]
	then
		echo | watch -e '

			PODLIST=$(kubectl get pod -n rook-ceph)

			echo "$PODLIST"
			echo
			echo
			echo " *** Waiting for OSD running... *** "
			echo
			echo " - This watch will exit automatically when a OSD is in running state."
			echo " - If this does not exit for more than about 10 mins, something might be wrong."
			echo "   You can exit from here by pressing following keys: \"Ctrl + C\""
			echo "$PODLIST" | tr -s " " | \
				grep "^rook-ceph-osd-" | grep -v "^rook-ceph-osd-prepare-" | \
				grep " Running " > /dev/null 2> /dev/null

			if [ $? -eq 0 ]
			then
				exit 1
			fi
		'
	fi



	exit "$EXIT_CODE"

# uninstall mode
elif [ "$1" = "uninstall" ]
then



	# delete with yaml
	kubectl delete -f "$YAML_BASE_URL"/csi/cephfs/storageclass.yaml
	kubectl delete -f "$YAML_BASE_URL"/filesystem.yaml

	# set to cleanup all
	kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
	kubectl -n rook-ceph delete cephcluster rook-ceph

#	kubectl delete -f "$YAML_BASE_URL"/cluster.yaml
	kubectl delete -f "$YAML_BASE_URL"/crds.yaml
	kubectl delete -f "$YAML_BASE_URL"/operator.yaml
	kubectl delete -f "$YAML_BASE_URL"/common.yaml

	for CRD in $(kubectl get crd -n rook-ceph | awk '/ceph.rook.io/ {print $1}')
	do
		kubectl get -n rook-ceph "$CRD" -o name | \
		xargs -I {} kubectl patch {} --type merge -p '{"metadata":{"finalizers": [null]}}'
	done
	echo
	echo "*** To finish cleanup, you might also want to do cleanup on ALL K8S NODES      ***"
	echo "*** by executing the script: cleanup-rook-ceph-on-all-nodes-after-uninstall.sh ***"


# this should not be reached
else
	exit 255
fi
