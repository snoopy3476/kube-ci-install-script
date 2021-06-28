# CI Utils Install Script for Kubernetes
- Simple scripts for installing CI utils on on-premise Kubernetes
- Tested on Ubuntu 20.04, and Kubernetes v1.21.1
- Author: snoopy3476@outlook.com

## Usage
- Install all
  - Without rook ceph (helm, gitlab-k8s, jenkins-k8s):
  `$ ./install-all.sh no-ceph`
  - With rook ceph (helm, rook-ceph-shared-storage-k8s, gitlab-k8s, jenkins-k8s):
  `$ ./install-all.sh install-ceph`
    - This script will install:
      - Helm on local machine (need root privilege)
      - (If install-ceph) Rook Ceph - Shared Storage for K8s (https://github.com/rook/rook), on the namespace 'rook-ceph'
      - GitLab for K8s, on the namespace 'ci-gitlab'
      - Jenkins for K8s, on the namespace 'ci-jenkins'
  - In case that you want to set default time zone for GitLab and Jenkins, define `$CI_TIMEZONE` by something like:
  `$ CI_TIMEZONE='Asia/Seoul' ./install-all.sh install-ceph`
- Install separately:
  `$ ./scripts/install-(util_name).sh install`
  - After installing GitLab and Jenkins, initial ID/PW will be printed on terminal.
    - If you want them after clearing terminal outputs, execute followings:
      - GitLab (ID: root)
        - `kubectl -n ci-gitlab get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode; echo`
      - Jenkins (ID: admin)
        - `kubectl -n ci-jenkins get secret jenkins -ojsonpath='{.data.jenkins-admin-password}' | base64 --decode; echo`
  - GitLab and Jenkins will be installed as NodePort type on k8s currently.
    - Ports are defined as `$NODE_PORT` variable in each script.
    - Default ports (`$NODE_PORT`):
      - GitLab: 30330
      - Jenkins: 30331
  - In case that you want to set default time zone for GitLab or Jenkins, define `$GITLAB_TIMEZONE` or `$JENKINS_TIMEZONE` respectively by something like:
  `$ GITLAB_TIMEZONE='Asia/Seoul' ./scripts/install-gitlab-k8s.sh install`
  or 
  `$ JENKINS_TIMEZONE='Asia/Seoul' ./scripts/install-jenkins-k8s.sh install`
- Uninstall separately:
  `$ ./scripts/install-(util_name).sh uninstall`
