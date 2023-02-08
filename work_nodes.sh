# 3대의 가상 머신(w1~3-k8s)에 쿠버네티스 워커 노드를 구성하는 스크립트
# 마스터 노드에 구성된 클러스터에 조인이 필요한 정보가 코드화 되어있어 스크립트를 실행하기만 하면
# 편하게 워커 노드로서 쿠버네티스 클러스터에 조인됩니다.
#!/usr/bin/env bash

# config for work_nodes only 
# kubeadm을 이용해 쿠버네티스 마스터 노드에 접속합니다. 이때 연결에 필요한 토큰은
# 기존에 마스터 노드에서 생성한 123456.1234567890123456을 사용합니다.
# 간단하게 구성하기 위해 --discovery-token-unsafe-skip-ca-verification으로 인증을 무시하고,
# API 서버 주소인 192.168.1.10으로 기본 포트 번호인 6443번 포트에 접속하도록 설정합니다.
kubeadm join --token 123456.1234567890123456 \
             --discovery-token-unsafe-skip-ca-verification 192.168.1.10:6443