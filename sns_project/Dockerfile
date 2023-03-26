FROM adoptopenjdk/openjdk11
CMD ["./gradlew", "build"]
ARG JAR_FILE_PATH=target/*.jar
COPY ${JAR_FILE_PATH} app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]

# FROM openjdk:11-jdk
# # jar 파일이 복사되고, docker image를 구성하면서 명령어를 실행하면서 지지고 볶을 디렉토리 설정
# ENV APP_HOME=/usr/app/
# # 해당 디렉토리에서 작업을 시작하겠다는 구문
# WORKDIR $APP_HOME
# # jar 파일을 복사한다.
# COPY build/libs/*.jar application.jar
# EXPOSE 8080
# CMD ["java", "-jar", "application.jar"]
