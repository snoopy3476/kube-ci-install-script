#!/bin/bash

# GitLab installation for k8s
TMP_YAMLFILE=".gitlab-values.yaml"
K8S_NAMESPACE="ci-gitlab"
# k8s gitlab using ceph provisioner (https://github.com/rook/rook.git)
SC_NAME="rook-cephfs"
NODE_PORT="30330"


GITLAB_SVC_YAML="
apiVersion: v1
kind: Service
metadata:
  name: gitlab-webservice-default
  namespace: $K8S_NAMESPACE
spec:
  ports:
    - name: http-webservice
      nodePort: 0
      port: 8080
      protocol: TCP
      targetPort: 8080
    - name: http-workhorse
      nodePort: $NODE_PORT
      port: 8181
      protocol: TCP
      targetPort: 8181
  type: NodePort
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
		SC_NAME=""
	fi

	# install
	kubectl create ns "$K8S_NAMESPACE"

	helm repo add gitlab https://charts.gitlab.io/
	helm repo update
	helm upgrade --namespace "$K8S_NAMESPACE" --install gitlab gitlab/gitlab --timeout 600s \
		--set global.hosts.externalIP=127.0.0.1 \
		--set global.hosts.https=false \
		--set global.edition=ce \
		--set global.time_zone=Asia/Seoul \
		--set global.storageClass="$SC_NAME" \
		--set gitlab.gitaly.persistence.storageClass="$SC_NAME" \
		--set gitlab-runner.install=false \
		--set gitlab-runner.rbac.create=false \
		--set certmanager-issuer.email=tmax_commonsystem@googlegroups.com \
		--set certmanager.install=false \
		--set prometheus.server.persistentVolume.storageClass="$SC_NAME" \
		--set minio.persistence.storageClass="$SC_NAME" \
	&& echo "$GITLAB_SVC_YAML" | kubectl apply -n "$K8S_NAMESPACE" -f- \
	&& echo -e \
		"\n\n==========================="\
		"\n\e[31m[*** GitLab Login Info ***]\e[0m"\
		"\n - ID: \e[31mroot\e[0m"\
		"\n - PW: \e[30;41m$(kubectl -n $K8S_NAMESPACE get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode)\e[0m"\
		"\n===========================\n\n"
	EXIT_CODE=$?


	# watch for webservice running
	if [ "$EXIT_CODE" -eq 0 ]
	then
	        echo | watch -e '

	                PODLIST=$(kubectl get pod -n '"$K8S_NAMESPACE"')

	                echo "$PODLIST"
	                echo
			echo
	                echo " *** Waiting for Webservice running... *** "
			echo
	                echo " - This watch will exit automatically when a webservice is in running state."
			echo " - If this does not exit for more than about 10 mins, something might be wrong."
			echo "   You can exit from here by pressing following keys: \"Ctrl + C\""
	                echo "$PODLIST" | tr -s " " | \
	                        grep "^gitlab-webservice-default-" | \
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

	# uninstall
	helm uninstall -n "$K8S_NAMESPACE" gitlab
	kubectl delete ns "$K8S_NAMESPACE"

	exit $?


# this should not be reached
else
        exit 255
fi
