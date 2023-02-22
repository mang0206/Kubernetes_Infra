# 1개의 가상 머신을 쿠버네티스 마스터 노드로 구성하는 스크립트
# 쿠버네티스 클러스터를 구성할 때 꼭 선택해야 하는 컨테이너 네트워크 인터페이스(CNI, Container Network Interface)도 함께 구성

#!/usr/bin/env bash

# init kubernetes 
# kubeadm을 통해 쿠버네티스의 워커 노드를 받아들일 준비를 합니다. 먼저 토큰을 123456.1234567890123456으로 지정하고 
# tt1(time to live, 유지되는 시간)을 0으로 설정해서 기본값인 24시간 후에 토큰이 계속 유지되게 합니다.
# 그리고 워커 노드가 정해진 토큰으로 들어오게 합니다. 쿠버네티스가 자동으로 컨테이너에 부여하는 네트워크를 
# 172.16.0.0/16(172.16.0.1 ~ 172.16.255.254)으로 제공하고, 워커 노드가 접속하는 API 서버의 IP를
# 192.168.1.10으로 지정해 워커 노드들이 자동으로 API 서버에 연결되게 합니다.
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
--pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.1.10 

# config for master node only 
# 마스터 노드에서 현재 사용자가 쿠버네티스를 정상적으로 구동할 수 있게 설정 파일을 루트의 홈디렉터리(/root)에
# 복사하고 쿠버네티스를 이용할 사용자에게 권한을 줍니다.
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# config for kubernetes's network 
# 컨테이너 네트워크 인터페이스(CNI)인 캘리코(Calico)의 설정을 적용해 쿠버네티스의 네터워크를 구성합니다.
# ##캘리코 이해하기 https://velog.io/@200ok/Kubernetes-Calico-CNI-%EC%9D%B4%ED%95%B4%ED%95%98%EA%B8%B0 ##

# raw_address for gitcontent
raw_git="raw.githubusercontent.com/sysnet4admin/IaC/master/manifests" 

# config for kubernetes's network 
kubectl apply -f https://$raw_git/172.16_net_calico.yaml

# install bash-completion for kubectl 
yum install bash-completion -y 

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc