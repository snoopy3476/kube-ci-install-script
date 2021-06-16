# CI Utils Install Script for Kubernetes
- Simple scripts for installing CI utils on on-premise Kubernetes
- Tested on Ubuntu 20.04, and Kubernetes v1.21.1
- Author: snoopy3476@outlook.com

## Usage
- Install all (helm, local-path-provisioner-k8s, gitlab-k8s, jenkins-k8s):
  `$ ./install-all.sh`
  - This will install:
    - Helm on local machine (need root privilege)
    - Local Path Provisioner for K8s (https://github.com/rancher/local-path-provisioner), on the namespace 'local-path-storage'
    - GitLab for K8s, on the namespace 'ci-gitlab'
    - Jenkins for K8s, on the namespace 'ci-jenkins'
- Install separately:
  `$ ./scripts/install-(util_name).sh install`
  - After installing GitLab and Jenkins, initial ID/PW will be printed on terminal.
    - If you want them after clearing terminal outputs, execute followings:
      - GitLab (ID: root)
        - `kubectl -n ci-gitlab get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode`
      - Jenkins (ID: admin)
        - `kubectl -n $K8S_NAMESPACE get secret jenkins -ojsonpath='{.data.jenkins-admin-password}' | base64 --decode`
  - GitLab and Jenkins will be installed as NodePort type on k8s currently.
    - Ports are defined as `$NODE_PORT` variable in each script.
    - Default ports (`$NODE_PORT`):
      - GitLab: 30330
      - Jenkins: 30331
- Uninstall separately:
  `$ ./scripts/install-(util_name).sh uninstall`
