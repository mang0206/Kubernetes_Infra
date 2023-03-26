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

COPY build/libs/*.jar application.jar
# Set the command to run the application
CMD ["java", "-jar", "application.jar.jar"]
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
```

