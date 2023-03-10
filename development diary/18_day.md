쿠버네티스와 젠키스를 통한 ci/cd 실습 8일차
======

#### 1. jenkins를 기본 실습 설치 파일로 재설치 후 아래와 같이 jenkins gui를 통해 volume 설정 후 재 시도

<img src="https://user-images.githubusercontent.com/86212081/224203072-88a0909e-1a26-4c08-bc80-8be507cb6ca7.png" width=500>

volume 설정 전에는 pipeline build가 잘 작동했지만 hostPath volume 설정하자마자 어제와 같이 build가 진행되지 않는 오류 발생  

#### 2. hostpath가 아닌 nfs를 통해 jenkins volume mount 시도

<img src="https://user-images.githubusercontent.com/86212081/224206485-a989a90a-d51c-4939-b401-2b22b71401e0.png" width=500>


<img src="https://user-images.githubusercontent.com/86212081/224205916-76e5cd04-248b-4983-a114-cc5ce67e3a80.png" width=500>

마운트한 directory 확인해보면 잘 된것을 볼 수 있다.  
<img src="https://user-images.githubusercontent.com/86212081/224206657-a9bbf663-fb6a-4e4a-9e2a-636f3237b1a8.png" width=500>

이를 바탕으로 jenkins_config 파일의 volume mount 부분 수정 후 재설치 및 build까지 진행

- 실습 중 처음 안 사실

<img src="https://user-images.githubusercontent.com/86212081/224214140-1c1d810c-0ae1-4538-93a3-af27ff6fe047.png" width=1000>
kubernetes 이름 지을 때 '_' 는 사용하면 안된다.... '-' 이걸로 해야한다.

우여곡절 끝에 드디어 jenkins를 통해서 바뀐 index.html 파일로 nginx 실행 및 접속 까지 성공

<img src="https://user-images.githubusercontent.com/86212081/224215416-8428ec18-37f0-4336-9ae0-28e4f85fff05.png" width=550>

##### 3. index.html 수정, push 후 jenkins에서 다시 build해서 변화 확인하기

<img src="https://user-images.githubusercontent.com/86212081/224216208-1ad19421-696d-4652-bf3c-e5e364262efb.png" width=550>

정상적으로 잘 작동한다!!!!!!!!!!!!
이제 드디어 webhook 단계로 나아갈 수 있다.

webhook까지만 성공하면 ci/cd의 모든 파이프라인 완성이다.

현재까지의 코드
-> https://github.com/mang0206/indexfile_for_jenkins_test/tree/33357b8ccae04e6b77121b069ee24779cd2bc76b
