#!/bin/bash

# Jenkins installation for k8s
K8S_NAMESPACE="ci-jenkins"
# k8s jenkins using ceph provisioner (https://github.com/rook/rook.git)
SC_NAME="rook-cephfs"
JENKINSPVC="jenkins-pvc"
NODE_PORT="30331"



JENKINS_YAML="
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $JENKINSPVC
  namespace: $K8S_NAMESPACE
spec:
  storageClassName: ''
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $K8S_NAMESPACE
  namespace: $K8S_NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: 'true'
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: $K8S_NAMESPACE
rules:
- apiGroups:
  - '*'
  resources:
  - statefulsets
  - services
  - replicationcontrollers
  - replicasets
  - podtemplates
  - podsecuritypolicies
  - pods
  - pods/log
  - pods/exec
  - podpreset
  - poddisruptionbudget
  - persistentvolumes
  - persistentvolumeclaims
  - jobs
  - endpoints
  - deployments
  - deployments/scale
  - daemonsets
  - cronjobs
  - configmaps
  - namespaces
  - events
  - secrets
  verbs:
  - create
  - get
  - watch
  - delete
  - list
  - patch
  - update
- apiGroups:
  - ''
  resources:
  - nodes
  verbs:
  - get
  - list
  - watch
  - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: 'true'
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: $K8S_NAMESPACE
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $K8S_NAMESPACE
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:$K8S_NAMESPACE

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

	# check if defined provisioner is installed
        kubectl get sc | grep "^$SC_NAME " > /dev/null 2> /dev/null
        if [ "$?" != "0" ]
        then
                echo "Provisioner ($SC_NAME) does not exist."
                echo "Continuing with default provisioner..."
        else
                # set storageClass, if provisioner exists
                JENKINS_YAML=$(echo "$JENKINS_YAML" | sed "s/storageClassName: ''/storageClassName: $SC_NAME/g")
	fi

	# install
	kubectl create ns "$K8S_NAMESPACE"
	echo "$JENKINS_YAML" | kubectl apply -f-

	helm repo add jenkinsci https://charts.jenkins.io
	helm repo update
	helm install jenkins -n "$K8S_NAMESPACE" jenkinsci/jenkins \
		--set persistence.existingClaim="$JENKINSPVC" \
		--set controller.nodePort="$NODE_PORT" \
		--set controller.serviceType=NodePort \
		--set serviceAccount.create=false \
		--set serviceAccount.name="$K8S_NAMESPACE" \
		--set serviceAccount.annotations="{}" \
	&& echo -e \
		"\n\n==========================="\
                "\n\e[31m[*** Jenkins Login Info ***]\e[0m"\
                "\n - ID: \e[31madmin\e[0m"\
                "\n - PW: \e[30;41m$(kubectl -n $K8S_NAMESPACE get secret jenkins -ojsonpath='{.data.jenkins-admin-password}' | base64 --decode)\e[0m"\
                "\n===========================\n\n"




	exit $?

# uninstall mode
elif [ "$1" = "uninstall" ]
then



	helm uninstall jenkins -n "$K8S_NAMESPACE"
	kubectl delete ns "$K8S_NAMESPACE"
	kubectl delete clusterrole "$K8S_NAMESPACE"
	kubectl delete clusterrolebinding "$K8S_NAMESPACE"



# this should not be reached
else
        exit 255
fi
