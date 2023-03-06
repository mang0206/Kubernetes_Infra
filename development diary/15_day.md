쿠버네티스와 젠키스를 통한 ci/cd 실습 5일차
======

jenkins와 jenkins volumne 등 사전 준비가 끝났으므로 본격적으로 PipeLine 구성


#### 1. git에 nginx test를 위한 index.html 파일과 jenkins 파이프라인을 위한 JenkinsFile 파일이 있는 repository 생성


#### 2. jenkins와 git 연동을 위해 git credential 설정

#### 3. 1번에서 생성한 repository에 index.html 파일과 JenkinsFile 생성

Jenkinsfile
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
            kubectl create deployment my-nginx --image=192.168.1.10:8443/indexfile_for_jenkins_test
            kubectl expose deployment my-nginx --type=LoadBalancer --port=8080 \
                                                   --target-port=80 --name=my-nginx-svc
            '''
          }
        }
    }
}
```

Dockerfile
```
FROM nginx

LABEL Name=my_nginx
```

#### 4. Jenkins 파이프라인 생성 
생성 시 SCM을 선택하고 git repository와 credential 연결

<img src="https://user-images.githubusercontent.com/86212081/223032420-41eda13f-e80d-4046-8490-c31248dbcdcd.png" width = 500>

#### 5. build 시도

<img src="https://user-images.githubusercontent.com/86212081/223032485-7d74ee9c-5f2e-4733-b2ae-d0b82aa67313.png" width = 500>

#### 6. 실패
nginx deployment도 생성되고 loadbalance로 외부 포트와 연결까지는 되었지만
index.html파일이 임의로 생성한 파일이 아니라 기본 nginx파일이다.

<img src="https://user-images.githubusercontent.com/86212081/223032569-6a212db0-94dd-4a91-a3ed-c7f90f3e544a.png" width = 500>

<img src="https://user-images.githubusercontent.com/86212081/223032606-d83a79db-1eeb-473f-b12c-86f68ae56822.png" width = 500>
