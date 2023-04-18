Spring boot 2일차
======

#### 1. MySQL에서 데이터베이스 생성

#### 2. build Gradle에 의존성 등록

```
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'mysql:mysql-connector-java'
}
```
spring-boot-starter-data-jpa
- 스프링 부트용 Spring Data Jpa 추상화 라이브러리
- 스프링 부트 버전에 맞춰 자동으로 JPA 관련 라이브러리들의 버전을 관리해준다.

#### 3. application.properties에 MySQL 설정 추가하기

```
spring.datasource.url=jdbc:mysql://localhost:3306/{your_database_name}
spring.datasource.username={your_username}
spring.datasource.password={your_password}
spring.jpa.hibernate.ddl-auto=create
```

#### 4. domain 패키지, User 패키지, User 클래스 생성

도메인이란 게시글, 댓글, 회원 등 소프트웨어에 대한 요구사항 혹은 문제 영역

```java
import java.util.ArrayList;

@Getter
@NoArgsConstructor
@Entity
@Table(name = "users")
public class Users {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String user_id;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String nickname;

    @Column(nullable = false)
    private String user_name;

    // @ElementCollection
    // @CollectionTable(name = "friend_list", joinColumns = @JoinColumn(name = "user_id"))
    // @Column(name = "friend")
    // private List<String> friend;

    @Column(nullable = true)
    private String profile_img;

    @Column(nullable = true)
    private String background_img;

    @Column(nullable = true)
    private String bio;

    // @ElementCollection
    // @CollectionTable(name = "like_list", joinColumns = @JoinColumn(name = "user_id"))
    // @Column(name = "post_id")
    // private List<String> post_id;

    @Builder
    public User(String user_id, String password, String nickname, String user_name ) {
        this.user_id = user_id;
        this.user_id = password;
        this.user_id = nickname;
        this.user_id = user_name;
    }
}
```

#### 현재 빌드 관련해서 아래와 같은 오류 발생

```
* What went wrong:
Execution failed for task ':compileJava'.
> Could not resolve all files for configuration ':compileClasspath'.
   > Could not find mysql:mysql-connector-java:.
     Required by:
         project :

* Try:
> Run with --scan to get full insights.

* Get more help at https://help.gradle.org

Deprecated Gradle features were used in this build, making it incompatible with Gradle 8.0.

You can use '--warning-mode all' to show the individual deprecation warnings and determine if they come from your own scripts or plugins.    

See https://docs.gradle.org/7.6/userguide/command_line_interface.html#sec:command_line_warnings

BUILD FAILED in 4s
1 actionable task: 1 executed
```


#### 이후 스프링 개발은 https://github.com/mang0206/sns_spring 여기서 따로 진행
