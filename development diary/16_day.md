쿠버네티스와 젠키스를 통한 ci/cd 실습 6일차
======

지난 실습에서 deployment 생성 시 mount 설정한게 아니기 때문에 
index.html 파일이 변경되지 않은거라고 결론

deployment 생성 시 mount하기 위해 mount할 위치 파악

1. jenkinsfile을 보면 git pull 수행하고
2. docker build -t " " . 로 이미지 생성 및 pull 수행
3. 그 후 kubernetes deployment 생성 및 외부 접속을 위한 서비스 생성


2번을 보면 pull 했던 디렉토리에 쉘 스크립트가 위치하고 있어서 docker build -t " " . 명령이 바로 가능해보인다.  
그러므로 jenkins sh 위치에 index.html 파일도 같이 존재한다고 볼 수 있다.  
따라서 deployment의 컨테이너 mount 위치를 이곳으로 하면 가능할 것이다.  
  -> index.html파일만 mount하기 위해 git repository에서 index.html파일이 위치할 directory 생성 후 거기 안에 index.html 파일을 둔다.
 
현재 test를 위한 git repository 구성  
Jenkinsfile  
Dockerfile  
indexDirectory/index.html

실습에서 deployment까지는 불필요해보기 때문에 간단하게 pod 및 service를 위한 yaml파일 작성
```
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx
spec:
  containers:
    - name: my-nginx
      image: --image=192.168.1.10:8443/indexfile_for_jenkins_test
      ports:
      - containerPort: 80
      volumeMounts:
      - mountPath: "/usr/share/nginx/html"
        name: pv-hostpath
  volumes:
    - name: pv-hostpath
      hostPath:
        path: ./IndexDirectory
        type: Directory
---
apiVersion: v1
kind: Service
metadata:
  name: np-svc
spec:
  selector:
    app: my-nginx
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30000
  type: NodePort

```

pod와 서비스를 yaml 파일로 생성하기 때문에 jenkinsfile도 수정

```
pipeline {
    agent any
    
    environment {
        GIT_URL = "https://github.com/mang0206/indexfile_for_jenkins_test.git"
    }

    stages {
        stage('Pull') {
            steps {
                git url: "${GIT_URL}", 
                    branch: "main", 
                    credentialsId: "for_kubernetice"
            }
        }
        
        stage('docker build and push') {
            steps {
              sh '''
              docker build -t 192.168.1.10:8443/indexfile_for_jenkins_test .
              docker push 192.168.1.10:8443/indexfile_for_jenkins_test
              '''
            }
        }
        
        stage('deploy kubernetes') {
          steps {
            sh '''
            kubectl apply -f my_nginx.yaml
            '''
          }
        }
    }
}

```

<img src="https://user-images.githubusercontent.com/86212081/223630697-1ebff613-a7f9-44cd-985c-43201a39f1fb.png" width=500>
pod 및 service까지 생성에는 성공했지만

pod가 정상적으로 running 상태가 아닌 계속해서 ContainerCreating상태이다.

<img src="https://user-images.githubusercontent.com/86212081/223630965-17570bde-e382-41be-898c-476c00c9c477.png" width=500>  

log를 확인하고 싶지만 불가능한 상태

<img src="https://user-images.githubusercontent.com/86212081/223632488-340544b6-0967-4c54-be99-36f4a1cca181.png" width = 500>


descibe 명령으로 확인
```
kubectl describe po my-nginx
```

<img src="https://user-images.githubusercontent.com/86212081/223633261-bb672990-431b-4739-97d0-f246ffb5ce34.png" width=500>
경로 입력이 잘못된 것 같다.

해당 jenkins sh의 파일 상태를 확인하기 위해서 jenkins mount 폴더인 마스터 노드의 /nfs_shared/jenkins 폴더에서  
pull 한 index.html, dockerfile, jenkinsfile등을 찾아보려했지만 도저히 찾을 수 가 없었다.  

그래서 jenkins에서 log를 찍어보면서 찾기로 결정

jenkins stage pull 단계에서 pwd와, ls -al 명령을 추가 후 log확인

<img src="https://user-images.githubusercontent.com/86212081/223634999-5a2de694-af26-4eb6-81e5-8575172cd8b5.png" width=500>

deployment mount 위치를 상대경로가 아닌 절대 경로로 입력 후 다시 재시도

결과는 마찬가지이다.

<img src="https://user-images.githubusercontent.com/86212081/223636455-13b860a2-5931-4fe4-a14f-a43a20074371.png" width=500>

생각해보니깐 당연한 결과다  
지난 번 mount 실습때와 같은 이유인데 hostpath mount 경로는 pod가 생성된 노드를 기준으로 한다.  
그런데 현재 hostpath를 jenkins 경로로 작성했다. 이러면 해당 pod를 가진 노드에는 당연히 그 directory가 존재하지 않는다.

jenkins에서 pull한 파일을 다시 nfs를 사용해서 mount해야한다......
