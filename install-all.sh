#!/bin/bash


# install helm on local system for prerequesites,
# and then install rook-ceph, gitlab, and jenkins on k8s.


# check arg
if [ "$1" != "install-ceph" ] && [ "$1" != "no-ceph" ]
then
        echo "usage: $0 <mode>"
	echo
	echo "          <mode>: install-ceph | no-ceph"
	echo
	echo "                  * If you have no default dynamic provisioner on k8s,"
	echo "                    then [install-ceph] mode is recommended."
        echo
        exit 1
fi




# install helm
./scripts/install-helm.sh install && \


# install rook ceph (shared storage), if argument install-ceph is given
if [ "$1" = "install-ceph" ]
then
	./scripts/install-rook-ceph-shared-storage-k8s.sh install
fi && \


# install and configure jenkins for k8s
JENKINS_TIMEZONE=$CI_TIMEZONE ./scripts/install-jenkins-k8s.sh install && \


# install and configure gitlab for k8s
GITLAB_TIMEZONE=$CI_TIMEZONE ./scripts/install-gitlab-k8s.sh install


# return result code
exit $?
