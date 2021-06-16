#!/bin/bash



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

	# check installation
	which helm > /dev/null
	[ "$?" = 0 ] && echo "Helm is already installed!" && exit 0

	# check sudo
	sudo true
	if [ "$?" != 0 ]
	then
		echo "Root privilege check failed!"
		exit 1
	fi

	# install
	curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
	sudo apt install apt-transport-https --yes
	echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
	sudo apt update
	sudo apt install -y helm

	exit $?

# uninstall mode
elif [ "$1" = "uninstall" ]
then

	# check installation
	which helm > /dev/null
	[ "$?" != 0 ] && echo "Helm is already not installed!" && exit 0

	# check sudo
	sudo true
	if [ "$?" != 0 ]
	then
		echo "Root privilege check failed!"
		exit 1
	fi

        # uninstall
	if [ -f /etc/apt/sources.list.d/helm-stable-debian.list ]
	then
		sudo apt remove -y helm
		sudo apt autoremove -y
		sudo rm -f /etc/apt/sources.list.d/helm-stable-debian.list
		sudo apt update
	fi

        exit $?

# this should not be reached
else
        exit 255
fi
