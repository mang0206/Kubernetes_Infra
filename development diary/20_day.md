쿠버네티스 MySql Operate 실습
======

#### 현재 MySql Dbcluster인  InnoDBCluster 설치 및 생성과정이 정상적으로 작동하지 않는다.
<img src="https://user-images.githubusercontent.com/86212081/224518667-edfdda68-dfd9-4924-8145-e9912c664546.png" width=500>

#### describe로 상태확인
```
kubectl describe pod mycluster-0 -n mysql-cluster
```

<img src="https://user-images.githubusercontent.com/86212081/224519385-84c8a7ad-547d-4a9f-bd0b-8b4cfd51f69a.png" width=500>

pvc가 bound되지 않아있다고 한다.

#### 스테이트풀셋 확인

```
kubectl describe statefulset  mycluster -n mysql-cluster
```
<img src="https://user-images.githubusercontent.com/86212081/224519656-7d3f260a-75ae-4b3d-a074-c8518156e5a2.png" width=1000>

어떤 문제가 있는지 찾을 수 가 없다.  
별다른 error 로그가 없다.  

#### 어떤 문제가 있는지 찾아보기 위해 helm 차트부터 쭉 살펴보기

```
helm show values mysql-operator/mysql-innodbcluster
```

쭉 살펴보다가 podSpec 부분이 눈에 들어왔다  
<img src="https://user-images.githubusercontent.com/86212081/224519768-beebe73c-a7ff-43db-90c8-0e09c0dfe51e.png" width= 500>  

top 명령으로 남은 메모리 확인해보는데 이게 이유인가 싶기도 하다.  
<img src="https://user-images.githubusercontent.com/86212081/224519853-602ddbf2-3c2d-4600-a057-deb58d74bc09.png" width = 500>  

그래서 현재 가상 서버 구성파일인 vagrantfile에서 메모리 추가 후 재시도  

<img src="https://user-images.githubusercontent.com/86212081/224520970-7c629446-fa4c-4f87-b647-fdc19d75fad1.png" width=500>  
오류 발생........  

여차저차 해서 메모리 증가 시킨 후 설치 재시도했지만 같은 error 발생

<img src="https://user-images.githubusercontent.com/86212081/224521455-8a2df40d-6c05-4e0a-bd12-973a337ba9fe.png" width=500>
