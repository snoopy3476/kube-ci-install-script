#!/bin/bash

# Rook Ceph - Shared Storage
# More info: https://github.com/rook/rook
GIT_BRANCH=release-1.6
YAML_BASE_URL="https://raw.githubusercontent.com/rook/rook/$GIT_BRANCH/cluster/examples/kubernetes/ceph/"



# CONFIG VARIABLE BELOW IS NOT CHANGABLE FOR THE CURRENT VERSION #
K8S_NAMESPACE="rook-ceph"
SC_NAME="rook-cephfs"

CEPH_FS_YAML="
apiVersion: ceph.rook.io/v1
kind: CephFilesystem
metadata:
  name: myfs
  namespace: $K8S_NAMESPACE
spec:
  metadataPool:
    replicated:
      size: 3
  dataPools:
    - replicated:
        size: 3
  preserveFilesystemOnDelete: true
  metadataServer:
    activeCount: 1
    activeStandby: true
"

CEPH_SC_YAML="
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $SC_NAME
# Change "rook-ceph" provisioner prefix to match the operator namespace if needed
provisioner: $K8S_NAMESPACE.cephfs.csi.ceph.com
parameters:
  # clusterID is the namespace where operator is deployed.
  clusterID: $K8S_NAMESPACE

  # CephFS filesystem name into which the volume shall be created
  fsName: myfs

  # Ceph pool into which the volume shall be created
  # Required for provisionVolume: 'true'
  pool: myfs-data0

  # The secrets contain Ceph admin credentials. These are generated automatically by the operator
  # in the same namespace as the cluster.
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-cephfs-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: $K8S_NAMESPACE
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-cephfs-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: $K8S_NAMESPACE
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-cephfs-node
  csi.storage.k8s.io/node-stage-secret-namespace: $K8S_NAMESPACE

reclaimPolicy: Delete
"







# check arg
if [ "$#" != "1" ] || [ "$1" != "install" -a "$1" != "uninstall" ]
then
	echo "usage: $0 <mode>"
	echo
	echo "          <mode>: install | uninstall"
	echo
	exit 1
fi



# install mode
if [ "$1" = "install" ]
then

	# install yaml
	kubectl apply -f "$YAML_BASE_URL"/common.yaml && \
	kubectl apply -f "$YAML_BASE_URL"/operator.yaml && \
	kubectl apply -f "$YAML_BASE_URL"/crds.yaml && \
	kubectl apply -f "$YAML_BASE_URL"/cluster.yaml && \
	kubectl apply -f "$YAML_BASE_URL"/filesystem.yaml && \
	kubectl apply -f "$YAML_BASE_URL"/csi/cephfs/storageclass.yaml
#	helm repo add rook-release https://charts.rook.io/release
#	kubectl create ns "$K8S_NAMESPACE"
#	helm install --namespace "$K8S_NAMESPACE" rook-ceph rook-release/rook-ceph && \
#	helm install --namespace "$K8S_NAMESPACE" rook-ceph --set operatorNamespace="$K8S_NAMESPACE" rook-release/rook-ceph-cluster && \
#	echo "$CEPH_FS_YAML" | kubectl apply -f- && \
#	echo "$CEPH_SC_YAML" | kubectl apply -f-
	exit $?


# uninstall mode
elif [ "$1" = "uninstall" ]
then


	kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
	kubectl -n rook-ceph delete cephcluster rook-ceph


	# delete with yaml
	kubectl delete -f "$YAML_BASE_URL"/csi/cephfs/storageclass.yaml
	kubectl delete -f "$YAML_BASE_URL"/filesystem.yaml
	kubectl delete -f "$YAML_BASE_URL"/cluster.yaml
	kubectl delete -f "$YAML_BASE_URL"/crds.yaml
	kubectl delete -f "$YAML_BASE_URL"/operator.yaml
	kubectl delete -f "$YAML_BASE_URL"/common.yaml
#	helm delete --namespace "$K8S_NAMESPACE" rook-ceph-cluster
#	helm delete --namespace "$K8S_NAMESPACE" rock-ceph
#	kubectl delete ns "$K8S_NAMESPACE"

#	for CRD in $(kubectl get crd -n "$K8S_NAMESPACE" | awk '/ceph.rook.io/ {print $1}'); do
#		kubectl get -n "$K8S_NAMESPACE" "$CRD" -o name | \
#		xargs -I {} kubectl patch {} --type merge -p '{"metadata":{"finalizers": [null]}}'
#	done

#	helm template rock-ceph rook-release/rook-ceph --namespace "$K8S_NAMESPACE" | kubectl delete -f-



#	kubectl delete podsecuritypolicies.policy 00-rook-privileged

	echo "*** To finish rook ceph cleanup, You also need to delete /var/lib/rook on ALL K8S NODES! ***"

	#exit $?

# this should not be reached
else
	exit 255
fi
