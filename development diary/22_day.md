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
