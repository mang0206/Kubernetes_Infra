쿠버네티스 MySQL 실습
======
MySQL Operator 방법으로는 실패했기 때문에 MySQL 컨테이너 방식으로 진행

1. DB 전용 노드 설정
2. Statefulset으로 mysql 생성
3. Spring Boot로 Test 진행

#### 1. DB 전용 노드 설정
DB의 경우 안정성이 중요하기 때문에 특정 노드에서만 동작하도록 설정

Taint & Toleration  
Taint 로 특정 노드에 역할을 부여하여 역할을 허용 하는 Toleration 을 가진 Node에만 스케줄링 허용

노드에 Taint 추가하기
```
kubectl taint nodes w3-k8s db=mysql:NoSchedule

Taint 취소를 원하면  끝에 - 를 붙이면 된다 -> kubectl taint nodes w3-k8s db=mysql:NoSchedule-
```

이후 pod 생성시 아래와 같이 spec을 지정해 주면된다.

```
tolerations:
- key: "db"
  operator: "Equal"
  value: "mysql"
  effect: "NoSchedule"
```

#### 2. Statefulset으로 mysql 생성


mysql statefulset yaml 파일
```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      terminationGracePeriodSeconds: 10
      tolerations:
        - key: "db"
          operator: "Equal"
          value: "mysql"
          effect: "NoSchedule"
      containers:
        - name: mysql
          image: mysql:5.7
          ports:
            - protocol: TCP
              containerPort: 3306
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: sns
            - name: MYSQL_DATABASE
              value: sns
          
          volumeMounts:
            - name: data
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        storageClassName: standard
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
```
이렇게 까지만 해서 statefulset을 생성하게 되면 pod가 pendding 상태가 된다.  
statefulset 생성 시 pvc가 자동으로 생성되기 때문에 미리 pv를 만들어서 bound되게끔 해줘야 pendding 상태가 되지 않는다.

pv yaml 파일
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  claimRef:
    name: data-mysql-0
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mysql
  tolerations:
    - key: "db"
      operator: "Equal"
      value: "mysql"
      effect: "NoSchedule"
```

claimRef.name을 통해 statefulset에서 생성된 pvc와 bound 가능하다.
pvc 생성 규칙은 statefulset.volumeClaimTemplates.name-statefulset.name-index이다.  

이렇게 해서 재시도 결과 아래와 같은 오류 발생

<img src="https://user-images.githubusercontent.com/86212081/225791072-464fd517-8dca-4d3b-a656-95ffeba7c533.png" width=1000>

storage class란 pvc 요청이 있을때 동적으로 pv를 생성해주게 미리 정의해 놓은 것이다. 지금은 정적으로 pv를 생성해 주었기 때문에 그냥 주석처리해준다.
수정 한김에 namespace도 같이 설정해 줘서 생성되는 pv, statefulset, service등을 같이 관리해준다.


#### namespace pod describe 방법
```
kubectl describe pod pod-name --namespace namespace-name
```

수정 후 재시도 했지만 아래와 같은 오류 발생
<img src="https://user-images.githubusercontent.com/86212081/225796548-5888565e-6e39-4432-a6fa-b50faac3f1b5.png" width= 1000>

yaml 파일 살펴봤는데 accessmode가 pv는 ReadWriteMany로 pvc는 ReadWriteOnce로 달랐기 때문에 발생한 오류라고 생각했는데. 수정 후 재시도해도 같은 오류 발생

storage class를 만드는 것으로 시도

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: mysql-storage
  namespace: my-mysql
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```
sotorageclass 생성후 pv와 volumeclaimtemplate에 strorageclass 명시 후 재시도 했지만 아래와 같은 오류 발생 

<img src="https://user-images.githubusercontent.com/86212081/225809849-b29143c7-6197-485b-9d56-7ebc4fd2329b.png" width=1000>

현재 statefulset에 의해 생성된 pvc가 계속해서 mount 되지 않는 오류가 발생하고 있다.....

지금까지 진행한 yaml 파일

  ->  https://github.com/mang0206/indexfile_for_jenkins_test/commit/6908f3eb95c41acae4d0f178433d2e69f0e28ef2
