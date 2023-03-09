어제 실습 마저 진행(외부 ip에서 pod 접속)

deployment로 생성한 pod와 yaml 파일로 생성한 nodeport service는 접속 불가

run으로 생성한 단순 pod와 expose로 생성한 service로 시도 시 성공
    (Kubectl expose pod [pod 이름] --type=Nodeport --port=포트번호)

deployment로 생성한 pod도 expose로 생성한 service로 시도 시 성공

서비스의 yaml 파일이 문제인 것을 파악

expose로 생성한 서비스와 yaml 파일로 생성한 서비스 비교

expose로 생성한 서비스
[root@m-k8s ~]# kubectl describe service my-nginx
Name:                     my-nginx
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 run=my-nginx
Type:                     NodePort
IP:                       10.102.255.174
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  32614/TCP
Endpoints:                172.16.132.6:80,172.16.221.133:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

yaml 파일로 생성한 서비스
[root@m-k8s ~]# kubectl describe service np-svc
Name:                     np-svc
Namespace:                default
Labels:                   <none>
Annotations:              Selector:  app=my-nginx
Type:                     NodePort
IP:                       10.107.212.135
Port:                     http  80/TCP
TargetPort:               80/TCP
NodePort:                 http  31323/TCP
Endpoints:                <none>
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

비교결과 yaml 파일로 생성한 서비스의 경우 endpoint가 설정되지 않은것을 볼 수 있다.

endpoint는 Service가 트래픽을 전달하고자 하는 Pod의 집합이다.
Endpoints는 실제로 Endpoints Controller에 의해 관리되는데, 
이 Endpoints Controller는 마스터 노드의 Controller Manager에 의해 관리된다.
Endpoints Controller는 API Server를 감시하고있다가 Service에 유효한 Pod가 추가되면 
해당 Pod를 Endpoints 목록에 추가하고, Pod가 삭제되면 해당 Pod를 Endpoints 목록에서 삭제한다.

yaml 파일로 생성한 서비스의 Endpoints가 할당되지 않은 이유는 아직 Service의 라벨 셀렉터에 해당하는 Pod가 없기 때문이라고한다.

실습중인 서비스 yaml 파일
*******************
apiVersion: v1
kind: Service
metadata:
  name: np-svc
spec:
  selector:
    app: my-nginx       <--------
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30000
  type: NodePort

실습중인 deployment yaml 파일
*******************
apiVersion: apps/v1     #사용할 API 버젼
kind: Deployment        #우리가 배포할 오브젝트의 종류
metadata:               #배포할 오브젝트의 정보
  name: my-nginx        #deployment의 이름
spec:                   #배포할 오브젝트의 명세
  selector:             # selector의 레이블 지정
    matchLabels:        #이것과 매칭되는 라벨을 소유한 pod을 책임진다
      run: my-nginx
  replicas: 2           #pod 개수
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

확인결과 실습한 deployment의 yaml 파일에서 lable 정의를 run: my-nginx로 지정했고
service yaml 파일에서는 selector를 app: my-nginx로 했기 때문에 매칭이 정상적으로 되지 않았다.

deployment yaml 파일 lable을 app: my-nginx에서로 수정 한 후 드디어 접속 성공

app과 run의 차이점은 없다 그저 label에서 키 값을 app으로 정의하냐 run으로 정의하냐의 차이점일 뿐이다.
중요한 점은 "키, 값 둘다 맞아야 selector가 인식할 수 있다는 것이다."