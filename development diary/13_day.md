쿠버네티스와 젠키스를 통한 ci/cd 실습 3일차

ci/cd에서의 헬름 역할 이해
CI부분을 젠킨스를 통해 소스 코드를 테스트 & 컨테이너 빌드,푸시 & 쿠버네티스 환경으로 배포하고 
CD부분을 helm을 통해 서비스 배포에 필요한 환경 설정 등을 정의한 helm chart를 통해 빠르고 쉽게 배포할 수 있는 것이다.

차트
다양한 요구 조건을 처리할 수 있는 패키지
각 사용자는 공개된 저장소에 등록된 차트를 이용해 애플리케이션을 원하는 형태로 쿠버네티스에 배포할 수 있습니다.
헬름의 기본 저장소는 아티팩트허브입니다. 여기서 설치할 패키지의 경로를 확인할 수 있습니다.

헬름 작동 과정 이해

생산자 영역: 
생산자가 헬름 명령으로 작업 공간을 생성하면 templates 디렉터리로 애플리케이션 배포에 필요한 여러 야믈 파일과 
구성 파일을 작성할 수 있다. 이때 templates 디렉터리에서 조건별 분기, 값 등을 처리할 수 있도록 values.yaml에 설정된 키를 사용한다.

필요한 패키지의 여러 분기 처리나 배포에 대한 구성이 완료되면 생산자는 차트의 이름, 목적, 배포되는 애플리케이션 버전과 같은 패키지 정보를
charts.yaml에 채워 넣는다.

즉 values.yaml은 여러 설정 등을 담고, charts.yaml은 명세서 역할인 것 같다.

사용자 영역:
사용자는 설치하려는 애플리케이션의 차트 저장소 주소를 아티팩트허브에서 얻으며 헬름을 통해 주소를 등록한다.
그리고 이를 최신으로 업데이트한 이후에 차트를 내려받고 설치한다.
이렇게 헬름을 통해 쿠버네티스에 설치된 애플리케이션 패키지를 릴리스(Release)라고한다.
헬름을 통해 배포된 릴리스를 다시 차트를 사용해 업그레이드할 수 있고 원래대로 되돌릴 수 있으며 사용하지 않는 헬름 릴리스를 제거할 수도 있다.


1. Jenkins를 위한 볼륨 생성
```
pv
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: 192.168.1.10
    path: "/mnt/jenkins"
```
pvc
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins
spec:
  accessModes: # AccessModes
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```
다수의 오브젝트 배포 야믈은 파일 구분자인 '---'로 묶어 단일 야믈로 작성해 배포 가능하다.
위 pv, pvc 파일을 하나의 파일로 수정
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: 192.168.1.10
    path: "/mnt/jenkins"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins
spec:
  accessModes: # AccessModes
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```
