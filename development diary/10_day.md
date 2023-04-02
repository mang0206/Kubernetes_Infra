아직 볼륨 실습 중

실습 중 안것
pod 가 계속해서 contianer creating 상태라면 yaml 파일의 문법이 잘못되었거나 논리적으로 맞지 않다는 뜻이다.

이럴때는 yaml 파일을 보면서 확인하는 것보다 describe 명령으로 오류를 쉽게 찾을 수 있다

kubectl describe pods
이렇게 확인한 결과
```
Events:
  Type     Reason       Age                 From               Message
  ----     ------       ----                ----               -------
  Normal   Scheduled    107s                default-scheduler  Successfully assigned default/my-nginx to w2-k8s
  Warning  FailedMount  43s (x8 over 107s)  kubelet, w2-k8s    MountVolume.SetUp failed for volume "test-hp" : hostPath type check failed: /root/data is not a directory
/root/data가 디렉터리가 아니라고한다

Events:
  Type     Reason       Age                From               Message
  ----     ------       ----               ----               -------
  Normal   Scheduled    42s                default-scheduler  Successfully assigned default/my-nginx to w1-k8s
  Warning  FailedMount  10s (x7 over 42s)  kubelet, w1-k8s    MountVolume.SetUp failed for volume "test-hp" : hostPath type check failed: /data is not a directory
```
디렉토리를 새로 만들고 시도해봐도 같은 결과가 나온다

구굴링으로 원인 파악.....
실습한 hostpath의 경우 마스터 노드에 directory를 만들고 그 path를 작성했었다.
하지만 pod가 작동되는 것은 워크 노드로 당연히 워크 노드에는 해당하는 directory가 없으므로 오류가 날 수 밖에 없었다.

실습하기 전에 document를 좀더 꼼꼼히 봐야할 필요를 느꼈다.

단일 노드가 혹은 해당 pod의 노드가 지정되어있는게 아니라면 hostpath는 사용하는게 맞지 않다.



nfs를 사용한 pv, pvc로 볼륨 마운트 시도

nfs 서비스 시작
```
systemctl start nfs-server.service
```
nfs설정
공유할 폴더 생성후 NFS 서비스 설정파일 수정 공유할 디렉터리 경로와 현재 사용하고 있는 서버 인스턴스의 서브넷 범위를 지정
```
echo '/nfs_shared 192.168.1.0/24(rw,sync,no_root_squash)' >> /etc/exports
```
재 부팅시 자동으로 시작하게 하기
```
systemctl enable nfs-server.service
```

nfs 서비스 상태 확인
```
systemctl status nfs-server.service

● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Mon 2023-02-27 12:23:15 KST; 35min ago
 Main PID: 21600 (code=exited, status=0/SUCCESS)
    Tasks: 0
   Memory: 0B
   CGroup: /system.slice/nfs-server.service

Feb 27 12:23:15 m-k8s systemd[1]: Starting NFS server and services...
Feb 27 12:23:15 m-k8s systemd[1]: Started NFS server and services.
```

##### pv
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: mm
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: 192.168.1.10
    path: "/nfs_shared"
```
###### pvc
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes: # AccessModes
  - ReadWriteOnce
  volumeMode: Filesystem
  storageClassName: mm 
  resources:
    requests:
      storage: 100Mi
```
###### pod
```
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx
spec:
  containers:
    - name: my-nginx
      image: nginx
      ports:
      - containerPort: 80
      volumeMounts:
      - mountPath: "/usr/share/nginx/html"
        name: nfs-vol
  volumes:
    - name: nfs-vol
      persistentVolumeClaim:
        claimName: nfs-pvc
```
드디어 볼륨 마운트 연결 성공
