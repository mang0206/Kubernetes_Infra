쿠버네티스와 젠키스를 통한 ci/cd 실습 2일차

여차저차해서 helm까지 설치 완료

ci/cd 파이프라인
```
                                                          사용자  
                                                            |
코드 git push -> github에서의 webhook -> jenkis인식  -> 쿠버네티스 서비스       <-   쿠버네티스 pod
                                                                                     ^    
                                                    -> 도커 컨테이너 Build & Push | Pull

```
