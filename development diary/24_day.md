쿠버네티스 MySQL 실습
======

우선 mysql password, root path 등을 위한 secreat과, configmap 생성 및 mysql service 생성

secret의 경우 base64로 인코딩값으로 넣어야 하지만 data가 아닌 stringdata를 사용하면 
```
apiVersion: v1
kind: Secret
metadata:
  name: secret-mysql
  namespace: my-mysql
type: Opaque
stringData:
    root-password: sns-root
    user-password: sns
```
kustomization 으로 생성할때 사용하는 명령어
```
kubectl apply -k 해당디렉토리
```

configmap과 서비스
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-mysql
  namespace: my-mysql
data:
  MYSQL_USER: sns
  MYSQL_DATABASE: sns
  MYSQL_ROOT_HOST: %
---
apiVersion: v1
kind: Service
metadata:
  name: service-mysql
spec:
  type: NodePort
  selector:
    app: mysql
  ports:
    - protocol: TCP
      port: 3306
      nodePort: 30306
      targetPort: 3306
```

주의할점: secret에 statefulset과 같은 namespace를 주지 않으면 pod 생성시 secret을 찾지 못한다.

#### 생성된 pod에 접속해서 정상적으로 동작하는지 확인

```
kubectl exec -it pod/mysql-0 -n my-mysql /bin/bash
mysql -u root -p
```

