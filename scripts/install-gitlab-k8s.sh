#!/bin/bash

# GitLab installation for k8s
TMP_YAMLFILE=".gitlab-values.yaml"
K8S_NAMESPACE="ci-gitlab"
# k8s gitlab using local path provisioner (https://github.com/rancher/local-path-provisioner)
PROVISIONER="local-path"
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
	kubectl get sc | grep "^$PROVISIONER " > /dev/null 2> /dev/null
	if [ "$?" != "0" ]
	then
		echo "Provisioner ($PROVISIONER) does not exist."
		echo "Continuing with default provisioner..."
		echo
		echo "If you want to use local path provisioner,"
		echo "(https://github.com/rancher/local-path-provisioner)"
		echo "do uninstall gitlab -> install local path provisioner -> reinstall gitlab"
		PROVISIONER="''"
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
		--set global.storageClass="$PROVISIONER" \
		--set gitlab.gitaly.persistence.storageClass="$PROVISIONER" \
		--set gitlab-runner.install=false \
		--set gitlab-runner.rbac.create=false \
		--set certmanager-issuer.email=tmax_commonsystem@googlegroups.com \
		--set certmanager.install=false \
		--set prometheus.server.persistentVolume.storageClass="$PROVISIONER" \
		--set minio.persistence.storageClass="$PROVISIONER" \
	&& echo "$GITLAB_SVC_YAML" | kubectl apply -n "$K8S_NAMESPACE" -f- \
	&& echo -e \
		"\n\n==========================="\
		"\n\e[31m[*** GitLab Login Info ***]\e[0m"\
		"\n - ID: \e[31mroot\e[0m"\
		"\n - PW: \e[30;41m$(kubectl -n $K8S_NAMESPACE get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode)\e[0m"\
		"\n===========================\n\n"

	exit $?


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
