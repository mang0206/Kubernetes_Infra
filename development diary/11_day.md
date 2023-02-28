쿠버네티스와 젠키스를 통한 ci/cd 실습

컨테이너 인프라 환경에서 젠킨스를 사용하는 주된 이유는 애플리케이션을 컨테이너로 만들고 배포하는 과정을 자동화하기 위해서이다.
하지만 자동화 환경은 단순히 젠킨스용 파드만을 배포해서는 만들어지지 않는다.
젠킨스는 컨트롤러와 에이전트 형태로 구성한 다음 배포해야 하며 여기에 필요한 설정을 모두 넣어야 한다.

애플리케이션을 배포하기 위한 환경을 하나하나 구성하는 것은 매우 복잡하고 번거로운 일이며
고정된 값이 아니기 때문에 매니페스트로 작성해 그대로 사용할 수 없다. 구성 환경에 따라 많은 부분을 동적으로 변경해야 한다.

동적인 변경 사항을 간편하고 빠르게 적용할 수 있도록 도와주는 도구중 하나인 헬름의 도움을 받아 젠킨스를 설치한다.

헬름의 작동 원리
헬름은 쿠버네티스에 패키지를 손쉽게 배포할 수 있도록 패키지를 관리하는 쿠버네티스 전용 패키지 매니저이다.
일반적으로 패키지는 실행 뿐 아니라 실행 환경에 필요한 의존성 파일과 환경 정보들의 묶음이다.
그리고 패키지 매니저는 외부에 있는 저장소에서 패키지 정보를 받아와 패키지를 안정적으로 관리하는 도구이다.
패키지 매니저는 다양한 목적으로 사용되지만, 가장 중요한 목적은 설치에 필요한 의존성 파일들을 관리하고 간편하게
설치할 수 있도록 도와주는 것이다.

패키지 매니저 기능
패키지 검색: 설정한 저장소에서 패키지를 검색하는 기능을 제공, 이때 대부분 저장소는 목적에 따라 변경가능
패키지 관리: 저장소에서 패키지 정보를 확인하고, 사용자 시스템에 패키지 설치, 삭제, 업그레이드, 되돌리기 등을 할 수 있다.
패키지 의존성 관리: 패키지를 설치할 때 의존하는 소프트웨어를 같이 설치히고, 삭제할 때 같이 삭제할 수 있다.
패키지 보안 관리: 디지털 인증서와 패키지에 고유하게 발행되는 체크섬(Checksum)이라는 값으로 해당 패키지의
소프트웨어나 의존성이 변조됐는지 검사할 수 있다.

helm 설치

우선 helm을 설치하기 위한 brew 매니저 설치
1. brew는 소스를 다운 받아서 컴파일하는 방식으로 동작하므로 사전에 개발 도구를 설치해야 하며 루비로 개발되었으므로 ruby 인터프리터도 설치해야 합니다.
    - sudo yum groupinstall 'Development Tools' && sudo yum install curl file git ruby

2. 필요한 패키지를 설치했으면 다음 명령어를 수행하여 brew 설치를 진행합니다.
    - sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"

    (이 작업을 위해 git, curl upgrade 진행)

3. Linux brew는 패키지를 $HOME/.linuxbrew/Cellar에 설치하므로 초기화 파일에 반영하기 위해 .bash_profile에 아래의 내용을 추가 합니다.
    - echo 'export PATH="${HOME}/.linuxbrew/bin:$PATH"' >>~/.bash_profile
      echo 'export MANPATH="${HOME}/.linuxbrew/share/man:$MANPATH"' >>~/.bash_profile
      echo 'export INFOPATH="${HOME}/.linuxbrew/share/info:$INFOPATH"' >>~/.bash_profile

4. 추가 후 변경내용을 반영해 줍니다.
    - source .bash_profile

brew 설치 실패.... 
brew의 경우 root 사용자는 설치가 되지 않아 임시 사용자를 만든 후 설치 시도 했지만 성공하지 못했다...

다른 방식으로 설치 시도

helm document에 나와 있는 방법

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

이 방법도 실패....

현재 많은 설정을 임의대로 수정했기 때문에 가상환경 재설치 후 다시 실습 진행

