오브젝트 필드
이러한 쿠버네티스 오브젝트는 오브젝트 구성을 결정해주는 두 개의 오브젝트 필드가 있다.
1. spec
오브젝트를 생성할 대 리소스에 원하는 특징에 대한 설명을 제공
2. status
오브젝트의 현재 상태

이렇게 사용자가 원하는 오브젝트의 상태를 spec과 status로 정의하는데 이러한 값들을 .yaml 파일에 작성하고 실행시키면 .yaml 파일에 선언한 상태로 쿠버네티스 오브젝트가 구성된다.

디플로이먼트
기본 오브젝트만으로도 쿠버네티스를 사용할 수 있지만, 좀 더 효율적으로 사용하기 위해 이외의 기능을 조합하고 추가한 것이 디플로이먼트입니다.
파드와 레플리카셋에 대한 선언적 업데이트를 제공하며,
디플로이먼트는 .yaml 파일로 의도하는 상태를 설명하고, 디플로이먼트 컨트롤러가 현재 상태에서 의도하는 상태로 비율을 조정하며 변경합니다.

디플로이먼트 예제

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx # 디플로이먼트 이름 정의.
  labels:
    app: nginx # 디플로이먼트 레이블
spec:
  replicas: 2 # 지정된 수만큼의 pod를 생성하고 유지 
  selector:     # selector의 레이블 지정
    matchLabels:
      app: nginx
  template:     
    metadata: 
      labels:
        app: nginx # 파드에 레이블을 붙인다. 
    spec:       # 컨테이너 이미지 지정
      containers:
      - name: nginx   
        image: nginx   
        ports:
        - containerPort: 80   

이렇게 생성한 디플로이먼트를 생성하는 방법은

kubectl apply -f 디플로이먼트파일명.yaml
kubectl get rs # 레플리카셋 확인 
kubectl get pod  # 레플리카셋에 정의된 갯수만큼 pod 생겼는지 확인 

pod 삭제 방법 = kubectl delete pod 명

디플로이먼트로 생성된 pod는 다르다.
디플로이먼트는 .yaml 파일에 지정된 replica수만큼 항상 유지되도록 체크된다고 하였다.
그렇기에 아무리 우리가 위 명령어로 삭제해도 컨트롤러가 계속해서 지정된 replica pod 수를 맞추기위해 생성해내므로 의미가 없게된다..\

따라서, 디플로이먼트로 생성한 pod를 삭제하려면 상위 디플로이먼트가 삭제되어야 파드가 삭제된다.

디플로이먼트 pod 삭제 방법 = kubectl delete deployment 디플로이먼트명


*****************************************************

서비스 사용해서 pod 접속

쿠버네티스 접속하기 위한 방법은 3가지가 있다
1. ClusterIP
2. nodeport
3. LoadBalancer

- clusterip
클러스터 안에 있는 다른 pod들이 접근할 수 있도록 IP를 할당한다.
중요한 것은 내부 IP만을 할당하기 때문에 클러스터 외부에서는 접근이 불가하다.

- nodeport
외부에서 쿠버네치스 클러스터의 내부에 접속하는 가장 쉬운 방법은 노드포트 서비스를 이용하는 것이다.
노드퐃트 서비스를 설정하면 모든 워커 노드의 특정 포트를 열고 여기로 오는 모든 요청을 노드포트 서비스로 전달한다.
그리고 노드포트 서비스는 해당 업무를 처리할 수 있는 파드로 요청을 전달한다.

노드포트 서비스 열기는 deployment와 똑같이 kubectl apply -f 파일명.yaml으로 가능하다.

노드포트 예시

apiVersion: v1
kind: Service
metadata:
  name: np-svc
spec:
  selector:
    app: np-pods 
  ports:
    - name: http
      protocol: TCP
      port: 80 # 서비스 포트 
      targetPort: 80 # pod에 접근할 때 사용하는 포트 
      nodePort: 30000 # pod에 열어놓은 포트 
  type: NodePort

  ----------------------------------------------------------

  위 두 예제로 실습한 결과
  로컬에서 해당 node ip 주소와 port를 제대로 적어서 접속 시도했지만 접속이 되지않는다.
  node를 바꿔서(drain을 사용해서)해도 접속이 되지않는다.



    