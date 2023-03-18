쿠버네티스 MySQL 실습
======

local hostpath로 volume mount하는 방법은 계속해서 실패했기 때문에
statefulset의 volumeclaimtemplate를 nfs로 시도

#### 1. NFS 서버 설정

현재 master node에는 nfs 설정이 되어 있지만 db 전용 노드에는 nfs가 미 설치 상태이기 때문에 설치부터 시작

1. NFS서버 패키지 설치
```
yum install -y portmap nfs-utils libssapi
```
2. export 설정
```
echo '/mysql 192.168.1.0/24(rw,sync,no_root_squash)' >> /etc/exports
systemctl enable --now nfs

systemctl start nfs
systemctl start rpcbind
```

#### 2. Service Account 생성
NFS Provisioner Pod가  kubernetes cluster에 PV를 배포할 수 있는 권한이 필요하다  
PV를 배포할 수 있는 ClusterRole, Role을 가진 Service Account 를 생성  
해당 SA는 이후 NFS Provisioner Deployment에서 사용한다  
```
kind: ServiceAccount
apiVersion: v1
metadata:
  name: nfs-pod-provisioner-sa
---
kind: ClusterRole # Role of kubernetes
apiVersion: rbac.authorization.k8s.io/v1 
metadata:
  name: nfs-provisioner-clusterRole
rules:
  - apiGroups: [""] # rules on persistentvolumes
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-provisioner-rolebinding
subjects:
  - kind: ServiceAccount
    name: nfs-pod-provisioner-sa
    namespace: default
roleRef: # binding cluster role to service account
  kind: ClusterRole
  name: nfs-provisioner-clusterRole # name defined in clusterRole
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-pod-provisioner-otherRoles
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-pod-provisioner-otherRoles
subjects:
  - kind: ServiceAccount
    name: nfs-pod-provisioner-sa # same as top of the file
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: Role
  name: nfs-pod-provisioner-otherRoles
  apiGroup: rbac.authorization.k8s.io
```

#### 3. StorageClass 생성

Dynamic Provisioning을 위한 StorageClass 생성
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storageclass  
provisioner: nfs-test 
parameters:
  archiveOnDelete: "false"
```

#### 4. NFS Provisoner Deployment 배포
 
NFS Server를 Dynamic Provisioning으로 사용할 수 있도록 해주는 NFS Provisioner Pod를 Deployment로 배포

```
apiVersion: v1
kind: Namespace
metadata:
  name: my-mysql
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: my-mysql
spec:
  serviceName: mysql
  replicas: 2
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
        - key: db
          operator: Equal
          value: mysql
          effect: NoSchedule
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
        namespace: my-mysql
      spec:
        storageClassName: nfs-storageclass 
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 1Gi
```
pv가 동적으로 할당 되어 pvc가 bounding 되어야 하지만 아래와 같이 pendding 상태 그대로이다.

<img src="https://user-images.githubusercontent.com/86212081/226081665-46084871-74e9-471f-8014-bb4c705f438e.png" width=1000>
pv가 생성되지도 않았다.......

### provisioner helm으로 설치 후 재시도

```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm repo update

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.1.103 \
    --set nfs.path=/mysql \
    --set storageClass.provisionerName=nfs-storageclass 
```
이번에도 실패한줄 알았지만 아래와 같이 좀 기다려 보니깐 정상적으로 running상태가 되었다.

![image](https://user-images.githubusercontent.com/86212081/226083506-b20aecd0-34e6-438e-9308-4dd09f3a3723.png)
![image](https://user-images.githubusercontent.com/86212081/226083528-c80a6b80-348b-460a-9f84-70dc7d8c6a44.png)

처음 생성되고 정상적으로 running 상태로 되기 위해 약 3분이라는 시간이 지났다.  
지금까지는 이렇게 까지 기다려본적이 없었는데 아마 진행했던 실습중에서도 조금더 기다렸더라면 정상적으로
running 상태가 되었을 확률이 있어보인다. 동작하는 것에 기쁘기도 하지만 허무하다.......

암튼 정상적으로 실행되는것을 보았으니 statefulset 동작확인 하기전에
우선 생성된 pod가 db전용 node에만 생성된게 아니여서 toleration확인 
