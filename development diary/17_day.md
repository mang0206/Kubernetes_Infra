쿠버네티스와 젠키스를 통한 ci/cd 실습 7일차
======

mount 해결 과정

#### 1. jenkins mount를 위한 directory 생성 및 설정

```
mkdir /jenkins_shared
echo '/jenkins_shared 192.168.1.0/24(rw,sync,no_root_squash)' >> /etc/exports

system enable --now nfs
```

#### 2. jenkins 설정파일 수정
jenkins.config 파일에서 아래 코드 추가
```
- hostPathVolume:
    hostPath: "/jenkins_shared"
    mountPath: "/home/jenkins"
```
볼륨 설정 추가
추가 한 부분 - > https://github.com/sysnet4admin/_Book_k8sInfra/blob/e03b66a436bdfb1a9d5d7e0d1325bd9163b09822/ch5/5.3.1/jenkins-config.yaml#L60


#### 3. jenkins 재설치
helm으로 설치 했으므로 helm으로 삭제
```
helm uninstall jenkins
```
jekins 관련 derectory 삭제
```
rm -rf /nfs_shared/jenkins/*
```

jekins-config.yaml, jekins-install.sh 파일을 수정해서 재설치 시도
하지만 정상적으로 설치가 되지 않는다.  
log로 확인해보니 아래와 같은 오류가 있다.  
<img src="https://user-images.githubusercontent.com/86212081/223919569-b958ecc4-6c8f-45a8-9c09-75a22f7515f1.png" width=500>  
config 파일을 로컬 경로로 하면 인식하지 못하는것 같다.  
그래서 테스트를 위해 만들었던 git repogitory에 수정한 jekins_config.yaml 파일 올린 후 설치 재시도  

수정한 jenkins_install.sh 파일
```
#!/usr/bin/env bash
jkopt1="--sessionTimeout=1440"
jkopt2="--sessionEviction=86400"
jvopt1="-Duser.timezone=Asia/Seoul"
jvopt2="-Dcasc.jenkins.config=https://raw.githubusercontent.com/mang0206/indexfile_for_jenkins_test/main/jenkins_config.yaml"
jvopt3="-Dhudson.model.DownloadService.noSignatureCheck=true"

helm install jenkins edu/jenkins \
--set persistence.existingClaim=jenkins \
--set master.adminPassword=admin \
--set master.nodeSelector."kubernetes\.io/hostname"=m-k8s \
--set master.tolerations[0].key=node-role.kubernetes.io/master \
--set master.tolerations[0].effect=NoSchedule \
--set master.tolerations[0].operator=Exists \
--set master.runAsUser=1000 \
--set master.runAsGroup=1000 \
--set master.tag=2.249.3-lts-centos7 \
--set master.serviceType=LoadBalancer \
--set master.servicePort=80 \
--set master.jenkinsOpts="$jkopt1 $jkopt2" \
--set master.javaOpts="$jvopt1 $jvopt2 $jvopt3"

```

#### 4. mount한 directoy를 위한 service 생성
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: 192.168.1.10
    path: "/jenkins_shared"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins
spec:
  accessModes: # AccessModes
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi

```

#### 5. build 오류

jenkins 재설치 완료 되서 pipeline build 시도했지만 아래와 같이 오류가 발생하는 것이 아닌 시작조차 하지 못하는 상태이다.

<img src="https://user-images.githubusercontent.com/86212081/223941016-93562f9c-e711-4549-bd0e-2908024d81bc.png" width = 500>

<img src="https://user-images.githubusercontent.com/86212081/223943684-aad6c0b9-800f-472f-8590-2929942ebb38.png" width = 500>  
jenkins agent 생성 할 때 오류가 발생한것같다. 
