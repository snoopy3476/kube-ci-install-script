#!/bin/bash

# Local path dynamic provisioner
# More info: https://github.com/rancher/local-path-provisioner
YAML_URL="https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml"




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
	kubectl apply -f "$YAML_URL"
	exit $?


# uninstall mode
elif [ "$1" = "uninstall" ]
then

	# check if installed
	kubectl get sc | grep "^local-path " > /dev/null 2> /dev/null
	if [ "$?" != 0 ]
	then
		echo "Local path dynamic provisioner is not installed!"
		exit 1
	fi

	# delete with yaml
	kubectl delete -f "$YAML_URL"
	exit $?


# this should not be reached
else
	exit 255
fi
