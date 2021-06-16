#!/bin/bash

# install helm on local system for prerequesites,
# and then install local path provisioner, gitlab, and jenkins on k8s.


./scripts/install-helm.sh install && \
./scripts/install-local-path-provisioner-k8s.sh install && \
./scripts/install-gitlab-k8s.sh install && \
./scripts/install-jenkins-k8s.sh install

exit $?
