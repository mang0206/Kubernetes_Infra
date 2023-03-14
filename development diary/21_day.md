쿠버네티스 MySql Operate 실습
======

지난번엔 helm 차트로 설치 시도했지만 정상적으로 설치가 진행되지 않아서 이번엔 yaml 파일을 사용해서 kubectl 명령으로 직접 설치 진행

#### 1. 비밀번호 설정을 위한 screat 생성

```
kubectl create secret generic mypwds \
 --from-literal=rootUser=root \
 --from-literal=rootHost=% \
 --from-literal=rootPassword=" "
```

#### 2. yaml 파일로 db Cluster 생성
db생성을 위한 yaml 파일

 mycluster.yaml
```
apiVersion: mysql.oracle.com/v2
kind: InnoDBCluster
metadata:
  name: mycluste
spec:
  secretName: mypwds
  tlsUseSelfSigned: true
  instances: 3
  router:
    instances: 1
```

```
kubectl apply -f mycluster.yaml
```


하지만 아래와 같이 생성된 pod는 계속 pendding 상태이다

<img src="https://user-images.githubusercontent.com/86212081/224869142-b1aa58f0-70b2-44bd-84a9-8739b63e7d6b.png" width=500>

pod가 Pendding 상태일 뿐만 아니라 같이 설치되어야할 cluster service도 deployment도 설치 되지않는다..

공식 document나 mysql operator Git 서버에 나와있는 방식으로 시도해도 마찬가지다.
설치가 진행되지 않은거라 error log도 살펴볼 수 가 없다.....
