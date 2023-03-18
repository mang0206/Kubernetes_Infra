#### Taints & Tolerations 확인  
<img src="https://user-images.githubusercontent.com/86212081/226084776-716c8560-b2c9-4c67-91ea-3b1a40a59c48.png" width=600>
<img src="https://user-images.githubusercontent.com/86212081/226084807-f3fb4c75-1648-4191-9296-0dd8e20945ec.png" width=500>

설정은 잘 했지만 pod가 해당 node에만 생성되진 않는다.
test로 다른 node에도 taint 적용해서 toleration해 보았지만 정상적으로 작동하지 않는다.

<img src="https://user-images.githubusercontent.com/86212081/226085895-af8a13d6-b073-4b94-90cc-10faef688487.png" width=600>

현재 taint를 w2, w3 node에 설정한 상태이다.
그냥 pod 생성 시 w2, w3에는 pod가 생성되지 않는 것을 볼 수 있다.

<img src="https://user-images.githubusercontent.com/86212081/226087109-19b66aac-d396-496e-b21b-42225a0fa21c.png" width=600>

이를 미루어봤을 때 taint는 정상적으로 작동하고 있지만 toleration 과정에서 매칭이 잘 이루어지고 있지 않는 것 같다.



여러 test결과 Taint & Tolerations의 경우 단순히 key, value, effect로는 스케줄링을 허용하는 것일 뿐 아래와 같이 해당 node에 스케줄링을 강제하지는 않는다. 

<img src="https://user-images.githubusercontent.com/86212081/226087855-941e7dc4-46c0-4758-8dcc-7998b583dc71.png" width= 800>
위 사진은 w2 노드에 taint 설정 후 deployment replica를 7개로 한 상태이다. w2에도 pod가 생성되긴 했지만 다른 곳에도 생성된다.

조사 결과 Taint가 Pod가 배포되지 못하도록 하는 정책이라면, affinity는 Pod를 특정 Node에 배포되도록 하는 정책이다.

test한 yaml 파일
```
apiVersion: apps/v1     #사용할 API 버젼
kind: Deployment        #우리가 배포할 오브젝트의 종류
metadata:               #배포할 오브젝트의 정보
  name: my-nginx        #deployment의 이름
spec:                   #배포할 오브젝트의 명세
  selector:             # selector의 레이블 지정
    matchLabels:        #이것과 매칭되는 라벨을 소유한 pod을 책임진다
      run: my-nginx
  replicas: 3           #pod 개수
  template:             #배포할 pod의 템플릿
    metadata:
      labels:           #pod의 레이블
        run: my-nginx
    spec:               #컨테이너 이미지 지정
      containers:
      - name: my-nginx  #pod에 들어갈 컨테이너의 이름
        image: nginx    #컨테이너에서 사용할 이미지
        ports:
        - containerPort: 80 #pod에서 이 컨테이너가 사용할 포트번호
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - w2-k8s
```
<img src="https://user-images.githubusercontent.com/86212081/226089285-d1ec42ca-3a21-40c9-9705-e2fff6343221.png" width= 800>
정상적으로 특정 node에만 배포되었다.

이제 statefulset에 적용시켜 db node에 잘 생성되는지 확인

<img src="https://user-images.githubusercontent.com/86212081/226089545-b6d18fd3-6373-4e58-9c5d-bb9aabf371cf.png" width=800>
잘 적용되므로 최종적으로 taint와 affinity 둘다 사용해서 db 전용 node를 설정하고 해당 node에만 pod가 생성되는지 확인

지금까지 mysql statefulset 코드
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
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - w3-k8s
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
        storageClassName: nfs-client
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 1Gi
```
<img src="https://user-images.githubusercontent.com/86212081/226089690-f522ea54-fea7-4f76-9926-7addbaeffd63.png" width=800>
잘 생성되었다.

taint & toleration과 affinity를 명확하게 배웠다.
