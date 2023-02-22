#!/usr/bin/env bash

# install packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker & driving docker 
yum install docker-ce-18.09.9-3.el7 docker-ce-cli-18.09.9-3.el7 \
    containerd.io-1.2.6-3.3.el7 -y
systemctl enable --now docker

# install kubernetes cluster 
yum install kubectl-$1 kubelet-$1 kubeadm-$1 -y
systemctl enable --now kubelet

# git clone _Book_k8sInfra.git
# 전체 실행 코드를 마스터 노드에만 내려받도록 Vagrantfile에서 두번째 변수 Main을 넘겨 받습니다.
# 그리고 깃에서 코드를 내려받아 실습을 진행할 루트 홈디렉터리 (/root)로 옮깁니다.
# 배시 스크립트(.sh)를 find로 찾아서 바로 실행 가능한 상태가 되도록 chmod 700으로 설정 
if [ $2 = 'Main' ]; then
  git clone https://github.com/sysnet4admin/_Book_k8sInfra.git
  mv /home/vagrant/_Book_k8sInfra $HOME
  find $HOME/_Book_k8sInfra/ -regex ".*\.\(sh\)" -exec chmod 700 {} \;
fi
