오늘 목표 쿠버네티스 pv, pcv로 볼륨 마운트 성공하기
    -> 마스터 노드에 있는 nginx index파일을 외부 ip 접속으로 보기

현재 실습중인 pv, pcv, pod yaml 파일

##### pv
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath
spec:
  capacity:
    storage: 100Mi 
  volumeMode: Filesystem 
  accessModes: 
  - ReadWriteOnce
  storageClassName: mm
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /tmp/k8s_pv 
```
###### pvc
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-hostpath
spec:
  accessModes: # AccessModes
  - ReadWriteOnce
  volumeMode: Filesystem 
  resources:
    requests:
      storage: 100Mi
  storageClassName: mm
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
        name: pv-hostpath
  volumes:
    - name: pv-hostpath
      persistentVolumeClaim:
        claimName: pvc-hostpath
```
실패 후 공식 document 파일 그대로 시도

##### pv
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/tmp/k8s_pv"
```
###### pvc
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```
##### pod
```
apiVersion: v1
kind: Pod
metadata:
  name: task-pv-pod
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: task-pv-claim
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage
```
실습 결과 pv와 pvc는 잘 마운트 되었지만 pod에 exec로 접속결과 index.html은 존재 x  실패
성공하면 document와 실습 파일을 비교하면서 분석하려 했지만 document도 실패했기 때문에 다른 방법 모색

pv, pvc말고 hostpath를 사용해서 실습
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
        name: pv-hostpath
  volumes:
    - name: pv-hostpath
      hostPath:
        path: /tmp/k8s_pv
        type: Directory
```
여전히 exec로 접속결과 index.html은 존재 x
혹시 경로 문제일 수 도 있어서 같은 파일에서 hostPath의 path만 /root로 변경 후 시도

실패...
