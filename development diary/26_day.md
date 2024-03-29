Spring boot 1일차
======

현재 목표
사전작업 - 쿠버네티스에 spring boot 배포하고 service 생성 후 index 페이지 확인

1. user 관리를 위한 database table 생성
2. database와의 연동
3. spring boot 계층에 맞게 web layer, service layer, dao, dto, domain modele등 구성
4. 로그인 페이지와 회원가입 페이지, 빈 인덱스 페이지 구성
5. docker 이미지 파일 생성
6. 쿠버네티스 deployment로 배포 및 service를 통해 접속
7. 회원가입시 data가 database에 잘 저장되는지 확인
8. 로그인시 세션 적용
9. 로그인 성공할시 index 페이지 이동

#### 사전작업
1. kubenetes master 노드에서 현재 작업 파일 받은 후 이미지 build, 허브에 push
2. deployment와 service 생성
3. 해당 port로 접속해서 확인

> git 허브에서 특정 디렉터리 or 파일만 pull 하는 방법
> ```
> git init
> 
> git config core.sparseCheckout true
> 
> git remote add origin -f https://github.com/mang0206/sns_project_renewal.git
> 
> echo "sns_project/*"> .git/info/sparse-checkout
> 
> git pull origin main
> ```

build할 dockerfile
```
FROM openjdk:11-jdk

WORKDIR /app
# Copy the Gradle files to the container
COPY build.gradle .
COPY settings.gradle .
COPY gradlew .
COPY gradle ./gradle

# Download the dependencies
RUN ./gradlew dependencies

# Copy the application source code to the container
COPY src ./src

# Build the application
RUN ./gradlew build

# Expose port 8080
EXPOSE 8080

# COPY build/libs/*.jar application.jar
# Set the command to run the application
CMD ["java", "-jar", "build/libs/*.jar"]
```

spring boot 빌드에 대한 기본지식이 없어서 한참 해맸다... 아무튼 build 진행

```
docker build -t mysns .
```
윈도우에서 환경에서 파일 생성 시 기본 권한이 644로 설정되기 때문에 git pull 해온다음 bulid 하면 아래와 같은 오류가 발생한다.

<img src="https://user-images.githubusercontent.com/86212081/227753245-556edcb4-4860-4aa7-b118-4bc45743dc7d.png" width=500>

권한 수정 후 다시 시도
```
git update-index --add --chmod=+x gradlew
or
chmod=+x gradlew
```

<img src="https://user-images.githubusercontent.com/86212081/227756468-bc677e09-37e5-47e2-b654-25039551245c.png" width=500>
build가 잘 되었으므로 이제 이미지 push하고 deployment 실행

push의 경우 docker hub말고 이전에 설치해뒀던 사설 레지스트리인 docker private registry에 push  
docker private registry에 push하기 위해서는 build할 때 이미지명에 ip, port 번호를 넣어서 build 해야한다.  
build했던 이미지 삭제 후 진행
```
docker rmi mysns
docker build 192.168.1.10:8443/mysns .
docker push 192.168.1.10:8443/mysns
```
<img src="https://user-images.githubusercontent.com/86212081/227762487-de53de77-555d-4a74-b346-8ec468f8f6ee.png" width=600>

push가 완료 되었으므로 deployment 및 service 생성 후 확인

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysns
spec:
  selector:
    matchLabels:
      app: mysns
  replicas: 2
  template:
    metadata:
      labels:
        app: mysns
    spec:
      containers:
        - name: mysns
          image: 192.168.1.10:8443/mysns
          ports:
          - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: sns-service
spec:
  selector:
    app: mysns
  ports:
    - name: http
      protocol: TCP
      port: 8080
      targetPort: 80
      nodePort: 30000
  type: NodePort
```
현재 실습 진행 중 kubernets만으로도 컴퓨터 메모리를 다 사용하게되어 진행이 불가능할 정도로 렉이 걸린다... vagrant로 가상서버 cpu, memory downgrade 후 실습진행
downgrade후 다시 deployment실행하면 back-off 오류가 발생한다. 우선 리소스를 아끼기 위해 deployment가 아닌 단일 pod로 진행했지만 downgrade로 진행했을 때 아래와 같이 mysql pod에대한 resource가 부족하다.

<img src="https://user-images.githubusercontent.com/86212081/227817082-61ce87bb-b244-4c3d-9934-fe53ab15eb91.png" width=1000>

아쉽지만 쿠버네티스 실습은 인프라 및 파이프라인을 구축했던걸로 만족하고 spring boot 개발은 따로 local에서 진행...
