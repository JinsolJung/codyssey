# 내 컴퓨터에 개발자용 ‘작업실’ 꾸미기

터미널 파일·권한 조작부터 OrbStack 기반 Docker 실행, NGINX 커스텀 이미지, 포트 매핑, 바인드 마운트와 볼륨, Compose까지 직접 수행한 기록입니다.

> **기록 보존:** [읽기 쉽게 정리한 터미널 로그](evidence/manual-session.log)에서 명령·출력과 입력 중 오타를 확인할 수 있습니다. 실패·반복 실행과 지웠던 글자는 보존했으며, 새 실행 결과를 추가하지 않았습니다. 셸의 화면 재표시 때문에 일부 문자열이 중복될 수 있습니다.

## 실행 환경

| 항목 | 기록된 값 |
| --- | --- |
| OS | macOS 26.3.1 (a), 빌드 25D771280a |
| 셸 / 터미널 | zsh (`/bin/zsh`) / VS Code (`vscode`) |
| Git | 2.47.0 |
| Docker / 엔진 | 29.8.2 / OrbStack, aarch64, overlayfs |
| Docker Compose | v5.5.0 |

## 수행 항목과 증거

- [01. 환경 확인](#log-01)
- [02. 터미널 파일 조작](#log-02)
- [03. 파일·디렉터리 권한](#log-03)
- [04. Docker 기본 실행과 로그](#log-04)
- [05. Ubuntu 진입·종료와 exec](#log-05)
- [06. 자동완성 및 VS Code 명령 문제](#log-06)
- [07. Dockerfile과 웹 이미지 빌드](#log-07)
- [08. 포트 매핑과 운영 점검](#log-08)
- [09. 바인드 마운트 변경 전후](#log-09)
- [10. 볼륨 영속성과 리소스 정리](#log-10)
- [11. Compose 실행과 환경 변수](#log-11)

**Git 설정·연결 증거:** [Git 실행 로그](evidence/git-session.log)에 사용자 설정(마스킹), 기본 브랜치 설정, 원격 주소와 `git ls-remote` 실행 결과를 기록했습니다. GitHub CLI(`gh`)는 설치되어 있지 않습니다. VS Code의 GitHub 로그인·저장소 연동 화면은 별도 증거가 필요합니다.

**경로 주의:** 명령은 저장소 루트 `mission_lab`을 기준으로 읽으면 됩니다. `practice %`는 하위 실습 폴더이고 `root@…#`는 컨테이너 내부입니다. `$(pwd)/site`는 현재 체크아웃의 `site` 경로를 사용합니다. `sed -i ''`는 이 macOS 환경에서 사용한 문법으로, Linux에서는 보통 `sed -i`를 사용합니다.

## 실행 기록

긴 빌드·진행률 출력은 접어 두었습니다. 펼치면 반복된 진행률까지 확인할 수 있습니다.

<a id="log-01"></a>

### 01. 환경 확인

`sw_vers`, 셸·터미널 환경 변수, Git·Docker·Compose 버전과 `docker info`로 환경을 확인했습니다.

```text
mission_lab % sw_vers
ProductName:		macOS
ProductVersion:		26.3.1
ProductVersionExtra:	(a)
BuildVersion:		25D771280a
```

```text
mission_lab % echo "$SHELL"
/bin/zsh
```

```text
mission_lab % echo "${TERM_PROGRAM:-unknown}"
vscode
```

```text
mission_lab % git --version
git version 2.47.0
```

```text
mission_lab % docker --version
Docker version 29.8.2, build 7fc2dff
```

```text
mission_lab % docker info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}} Architecture={{.Architecture}} Driver={{.Driver}}'
Server=29.8.2 OS=OrbStack Architecture=aarch64 Driver=overlayfs
```

```text
mission_lab % docker compose version
Docker Compose version v5.5.0
```

<a id="log-02"></a>

### 02. 터미널 파일 조작

생성, 내용 확인, 복사, 이름 변경·이동, 숨김 파일을 포함한 목록 확인과 삭제를 수행했습니다. `pwd`를 직접 실행한 증거는 이 로그에서 확인되지 않습니다.

```text
mission_lab % mkdir -p practice
```

```text
mission_lab % cd practice
```

```text
practice % touch empty.txt
```

```text
practice % echo "Hello terminal" > original.txt
```

```text
practice % cat original.txt
Hello terminal
```

```text
practice % cp original.txt copy.txt
```

```text
practice % mv copy.txt renamed.txt
```

```text
practice % mkdir -p archive
```

```text
practice % mv renamed.txt archive/
```

```text
practice % ls -la archive
total 8
drwxr-xr-x@ 3 dhjung  staff   96 Nov  2 15:43 .
drwxr-xr-x@ 5 dhjung  staff  160 Nov  2 15:43 ..
-rw-r--r--@ 1 dhjung  staff   15 Nov  2 15:43 renamed.txt
```

```text
practice % rm archive/renamed.txt
```

```text
practice % rmdir archive
```

<a id="log-03"></a>

### 03. 파일·디렉터리 권한

동일 파일과 디렉터리를 `600 / 700`에서 `644 / 755`로 바꾸고 `ls -ld`로 비교했습니다. 권한은 소유자·그룹·기타 순서이며 r=4, w=2, x=1의 합입니다.

```text
practice % mkdir -p permissions
```

```text
practice % chmod 600 original.txt
```

```text
practice % chmod 700 permissions
```

```text
practice % ls -ld original.txt permissions
-rw-------@ 1 dhjung  staff  15 Nov  2 15:37 original.txt
drwx------@ 2 dhjung  staff  64 Nov  2 15:43 permissions
```

```text
practice % chmod 644 original.txt
```

```text
practice % chmod 755 permissions
```

```text
practice % ls -ld original.txt permissions
-rw-r--r--@ 1 dhjung  staff  15 Nov  2 15:37 original.txt
drwxr-xr-x@ 2 dhjung  staff  64 Nov  2 15:43 permissions
```

```text
practice % cd ..
```

```text
mission_lab % ls
evidence	practice
```

```text
mission_lab % clear
```

<a id="log-04"></a>

### 04. Docker 기본 실행과 로그

이미지 다운로드·목록, hello-world 성공, 실행 중·종료 컨테이너 목록과 로그를 확인했습니다. `dockr` 오타와 존재하지 않는 컨테이너 로그 조회도 남겼습니다.

```text
mission_lab % docker pull hello-world:latest
latest: Pulling from library/hello-world
58dee6a49ef1: Pulling fs layer
58dee6a49ef1: Download complete
58dee6a49ef1: Extracting 1 s
58dee6a49ef1: Extracting 1 s
58dee6a49ef1: Pull complete
c3bdf82c34d1: Download complete
Digest: sha256:c567b231f65614688711a75f31518a064258a51d442117a3e771a3a8fdba78ef
Status: Downloaded newer image for hello-world:latest
docker.io/library/hello-world:latest
```

```text
mission_lab % dockr images
zsh: command not found: dockr
```

```text
mission_lab % docker images
                                                                    i Info →   U  In Use
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
hello-world:latest   c567b231f656       18.5kB         10.3kB
```

```text
mission_lab % docker run --name codyssey-hello hello-world:latest
Hello from Docker!
This message shows that your installation appears to be working correctly.
To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (arm64v8)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash
Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/
For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

```text
mission_lab % docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```text
mission_lab % docker ps -a
CONTAINER ID   IMAGE                COMMAND    CREATED         STATUS                     PORTS     NAMES
888a3811b97e   hello-world:latest   "/hello"   9 minutes ago   Exited (0) 9 minutes ago             codyssey-hello
```

```text
mission_lab % docker logs codyssey_test1
Error response from daemon: No such container: codyssey_test1
```

```text
mission_lab % docker logs codyssey-hello
Hello from Docker!
This message shows that your installation appears to be working correctly.
To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (arm64v8)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash
Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/
For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

```text
mission_lab % docker rm codyssey-hello
codyssey-hello
```

<a id="log-05"></a>

### 05. Ubuntu 진입·종료와 exec

대화형 bash에서 `exit`한 뒤에는 컨테이너가 종료됐습니다. `sleep infinity`로 실행한 컨테이너는 `exec`로 들어간 bash를 종료한 뒤에도 `docker ps`에서 실행 중이었습니다.

```text
mission_lab % docker pull ubuntu:24.04
24.04: Pulling from library/ubuntu
e2d2bb84d022: Pulling fs layer
e2d2bb84d022: Downloading  1.049MB/28.94MB
e2d2bb84d022: Downloading  4.194MB/28.94MB
e2d2bb84d022: Downloading  8.389MB/28.94MB
e2d2bb84d022: Downloading  11.53MB/28.94MB
e2d2bb84d022: Downloading  16.78MB/28.94MB
e2d2bb84d022: Downloading  20.97MB/28.94MB
e2d2bb84d022: Downloading  23.07MB/28.94MB
e2d2bb84d022: Downloading  26.21MB/28.94MB
2238dc1b4376: Downloading  1.049MB/1.939MB
e2d2bb84d022: Downloading  28.94MB/28.94MB
2238dc1b4376: Downloading  1.939MB/1.939MB
e2d2bb84d022: Download complete
2238dc1b4376: Download complete
e2d2bb84d022: Extracting 1 s
e2d2bb84d022: Extracting 1 s
e2d2bb84d022: Extracting 1 s
e2d2bb84d022: Pull complete
Digest: sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852
Status: Downloaded newer image for ubuntu:24.04
docker.io/library/ubuntu:24.04
```

```text
mission_lab % docker run -it --name codyssey-ubuntu ubuntu:24.04 bash
```

<details>
<summary>전체 출력 펼치기 (반복 진행률 포함)</summary>

```text
root@68ee939a19dc:/# echo "Hello from Ubuntu"
Hello from Ubuntu
root@68ee939a19dc:/# #
root@68ee939a19dc:/#
(arg: 4)
root@68ee939a19dc:/# ls
bin   dev  home  media  opt   root  sbin  sys  usr
boot  etc  lib   mnt    proc  run   srv   tmp  var
root@68ee939a19dc:/# cd home/
root@68ee939a19dc:/home# ls
ubuntu
root@68ee939a19dc:/home# u
uclampset            unexpand             unshare              useradd
ulimit               uniq                 until                userdel
umask                unix_chkpwd          update-alternatives  usermod
umount               unix_update          update-passwd        users
unalias              unlink               update-rc.d          utmpdump
uname                unminimize           update-shells
uncompress           unset                uptime
root@68ee939a19dc:/home# cd ubuntu/
root@68ee939a19dc:/home/ubuntu# ls
root@68ee939a19dc:/home/ubuntu# echo "Hello from Ubuntu"
Hello from Ubuntu
root@68ee939a19dc:/home/ubuntu# cd ../../
root@68ee939a19dc:/# exit
exit
```

</details>

```text
mission_lab % docker ps -a
CONTAINER ID   IMAGE          COMMAND   CREATED         STATUS                     PORTS     NAMES
68ee939a19dc   ubuntu:24.04   "bash"    4 minutes ago   Exited (0) 7 seconds ago             codyssey-ubuntu
```

```text
mission_lab % docker start -ai codyssey-ubuntu
root@68ee939a19dc:/# exit
exit
```

```text
mission_lab % docker rm codyssey-ubuntu
codyssey-ubuntu
```

```text
mission_lab % docker run -d --name codyssey-keep ubuntu:24.04 sleep infinity
b6e9a3b8f31de1a07a4ec77a96ffdfd03c2e76e11c0142c032fbebf7119c8e24
```

```text
mission_lab % docker exec -it codyssey-keep bash
root@b6e9a3b8f31d:/#
(arg: 7)
root@b6e9a3b8f31d:/# root@b6e9a3b8f31d:/#
(arg: 7)
root@b6e9a3b8f31d:/# root@b6e9a3b8f31d:/# exit
exit
```

```text
mission_lab % docker ps
CONTAINER ID   IMAGE          COMMAND            CREATED              STATUS              PORTS     NAMES
b6e9a3b8f31d   ubuntu:24.04   "sleep infinity"   About a minute ago   Up About a minute             codyssey-keep
```

```text
mission_lab % docker stop codyssey-keep
codyssey-keep
```

<a id="log-06"></a>

### 06. 자동완성 및 VS Code 명령 문제

자동완성 설정 과정과 `code ~/.zshrc` 실패·재시도를 기록했습니다. 실패 뒤 같은 명령에서 오류 출력이 사라졌지만, PATH 수정 등 실제 해결 조치는 로그에 남아 있지 않습니다.

```text
mission_lab % echo $SHELL
/bin/zsh
```

```text
mission_lab % docker start
evidence/  practice/
docker startco
mkdir -p ~/.zsh/completionsmkdir -p ~/.zsh/completions
```

```text
mission_lab % ㅣㄴ
zsh: command not found: ㅣㄴ
```

```text
mission_lab % ls
evidence	practice
```

```text
mission_lab % docker completion zsh > ~/.zsh/completions/_docker
```

```text
mission_lab % code ~/.zshrc
zsh: command not found: code
```

```text
mission_lab % code ~/.zshrc
zsh: command not found: code
```

```text
mission_lab % code ~/.zshrc
```

```text
mission_lab % clear
```

```text
mission_lab % docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```text
mission_lab %
```

```text
mission_lab %
```

```text
mission_lab %
```

<a id="log-07"></a>

### 07. Dockerfile과 웹 이미지 빌드

기반은 `nginx:stable-alpine`입니다. [Dockerfile](Dockerfile)에 웹 콘텐츠 복사, 환경 변수로 포트 설정, `/health` 헬스체크를 추가했습니다. 설정 파일이 없던 시점과 이후 내용을 확인한 시점, 반복 빌드를 모두 보존했습니다.

```text
mission_lab % cat Dockerfile
cat: Dockerfile: No such file or directory
```

```text
mission_lab % cat Dockerfile
FROM nginx:stable-alpine
LABEL org.opencontainers.image.title="codyssey-workstation-lab"
ENV NGINX_PORT=8080
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY site/ /usr/share/nginx/html/
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null "http://127.0.0.1:${NGINX_PORT}/health" || exit 1
```

```text
mission_lab % cat nginx/default.conf.template
cat: nginx/default.conf.template: No such file or directory
```

```text
mission_lab %
```

```text
mission_lab %
```

```text
mission_lab % cat nginx/default.conf.template
server {
    listen ${NGINX_PORT};
    server_name _;
    root /usr/share/nginx/html;
    index index.html;
    location / { try_files $uri $uri/ =404; }
    location = /health {
        access_log off;
        default_type text/plain;
        return 200 "ok\n";
    }
}
```

```text
mission_lab % docker build -t codyssey-web:local .
```

<details>
<summary>전체 출력 펼치기 (반복 진행률 포함)</summary>

```text
[+] Building 0.0s (0/1)                                                 docker:orbstack
[+] Building 0.2s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.2s
[+] Building 0.3s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
[+] Building 0.5s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.5s
[+] Building 0.6s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.6s
[+] Building 0.8s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.8s
[+] Building 0.9s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.9s
[+] Building 1.1s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.1s
[+] Building 1.2s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.2s
[+] Building 1.4s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.4s
[+] Building 1.5s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.5s
[+] Building 1.7s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.7s
[+] Building 1.8s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.8s
[+] Building 2.0s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             2.0s
[+] Building 2.1s (2/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             2.1s
[+] Building 2.2s (4/7)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             2.1s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.1s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => [internal] load build context                                                  0.1s
 => => transferring context: 356B                                                  0.0s
[+] Building 2.3s (7/7) FINISHED                                        docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             2.1s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => CANCELED [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126  0.1s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => [internal] load build context                                                  0.1s
 => => transferring context: 356B                                                  0.0s
 => CACHED [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.co  0.0s
 => ERROR [3/3] COPY site/ /usr/share/nginx/html/                                  0.0s
------
 > [3/3] COPY site/ /usr/share/nginx/html/:
------
Dockerfile:5
--------------------
   3 |     ENV NGINX_PORT=8080
   4 |     COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
   5 | >>> COPY site/ /usr/share/nginx/html/
   6 |     EXPOSE 8080
   7 |     HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null "http://127.0.0.1:${NGINX_PORT}/health" || exit 1
--------------------
ERROR: failed to build: failed to solve: failed to compute cache key: failed to calculate checksum of ref poqpv1yea4splmv3d7ud2cvc7::woe5l24us6dnge1cr4a5tzm1m: "/site": not found
```

</details>

```text
mission_lab % docker build -t codyssey-web:local .
```

<details>
<summary>전체 출력 펼치기 (반복 진행률 포함)</summary>

```text
[+] Building 0.0s (0/1)                                                 docker:orbstack
[+] Building 0.2s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.2s
[+] Building 0.3s (1/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
[+] Building 0.3s (2/2)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
[+] Building 0.5s (5/7)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.1s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 0.6s (4/7)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.3s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 0.6s (4/7)                                                 docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.3s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e624 0B / 1.21kB  0.2s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e46354757f 0B / 19.86MB  0.2s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f28f4 0B / 1.40kB  0.2s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 0.8s (4/7)                                                 docker:orbstack
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.4s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e624 0B / 1.21kB  0.3s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e46354 2.10MB / 19.86MB  0.3s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f28f4 0B / 1.40kB  0.3s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f72 0B / 404B  0.3s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 0.9s (4/7)                                                 docker:orbstack
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.6s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e624 0B / 1.21kB  0.4s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e46354 8.39MB / 19.86MB  0.5s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f28f4 0B / 1.40kB  0.4s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f72 0B / 404B  0.4s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.1s (4/7)                                                 docker:orbstack
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.7s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e624 0B / 1.21kB  0.6s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e4635 16.78MB / 19.86MB  0.6s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f 1.40kB / 1.40kB  0.5s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f72 0B / 404B  0.6s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.2s (4/7)                                                 docker:orbstack
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.8s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062 1.21kB / 1.21kB  0.6s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e4635 19.86MB / 19.86MB  0.7s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f 1.40kB / 1.40kB  0.5s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f 404B / 404B  0.7s
 => => sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb9985f 0B / 963B  0.2s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.3s (4/7)                                                 docker:orbstack
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.9s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062 1.21kB / 1.21kB  0.6s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e4635 19.86MB / 19.86MB  0.7s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f 1.40kB / 1.40kB  0.5s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f 404B / 404B  0.7s
 => => sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb998 963B / 963B  0.2s
 => => sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e25435 0B / 627B  0.2s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.4s (4/7)                                                 docker:orbstack
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  1.1s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062 1.21kB / 1.21kB  0.6s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e4635 19.86MB / 19.86MB  0.7s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f 1.40kB / 1.40kB  0.5s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f 404B / 404B  0.7s
 => => sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb998 963B / 963B  0.2s
 => => sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e254 627B / 627B  0.2s
 => => sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce 1.05MB / 1.90MB  0.3s
 => => sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6 0B / 4.19MB  0.3s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.6s (4/7)                                                 docker:orbstack
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  1.2s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062 1.21kB / 1.21kB  0.6s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e4635 19.86MB / 19.86MB  0.7s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f 1.40kB / 1.40kB  0.5s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f 404B / 404B  0.7s
 => => sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb998 963B / 963B  0.2s
 => => sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e254 627B / 627B  0.2s
 => => sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce 1.90MB / 1.90MB  0.4s
 => => sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a6 4.19MB / 4.19MB  0.4s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.7s (5/7)                                                 docker:orbstack
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062 1.21kB / 1.21kB  0.6s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e4635 19.86MB / 19.86MB  0.7s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f 1.40kB / 1.40kB  0.5s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f 404B / 404B  0.7s
 => => sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb998 963B / 963B  0.2s
 => => sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e254 627B / 627B  0.2s
 => => sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce 1.90MB / 1.90MB  0.4s
 => => sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a6 4.19MB / 4.19MB  0.4s
 => => extracting sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6d  0.1s
 => => extracting sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce6884a  0.0s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.9s (4/7)                                                 docker:orbstack
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  1.5s
 => => sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a6 4.19MB / 4.19MB  0.4s
 => => extracting sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6d  0.1s
 => => extracting sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce6884a  0.0s
 => => extracting sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e2543  0.0s
 => => extracting sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb9985  0.0s
 => => extracting sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f7  0.0s
 => => extracting sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e6240  0.0s
 => => extracting sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f28f45  0.0s
 => => extracting sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e46354757f57  0.1s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 1.9s (5/7)                                                 docker:orbstack
 => => sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce 1.90MB / 1.90MB  0.4s
 => => sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a6 4.19MB / 4.19MB  0.4s
 => => extracting sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6d  0.1s
 => => extracting sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce6884a  0.0s
 => => extracting sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e2543  0.0s
 => => extracting sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb9985  0.0s
 => => extracting sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f7  0.0s
 => => extracting sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e6240  0.0s
 => => extracting sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f28f45  0.0s
 => => extracting sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e46354757f57  0.2s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
[+] Building 2.0s (7/7)                                                 docker:orbstack
 => => extracting sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6d  0.1s
 => => extracting sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce6884a  0.0s
 => => extracting sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e2543  0.0s
 => => extracting sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb9985  0.0s
 => => extracting sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f7  0.0s
 => => extracting sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e6240  0.0s
 => => extracting sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f28f45  0.0s
 => => extracting sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e46354757f57  0.2s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
 => [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.conf.temp  0.1s
 => [3/3] COPY site/ /usr/share/nginx/html/                                        0.0s
[+] Building 2.3s (7/8)                                                 docker:orbstack
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
 => [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.conf.temp  0.1s
 => [3/3] COPY site/ /usr/share/nginx/html/                                        0.0s
 => exporting to image                                                             0.2s
 => => exporting layers                                                            0.0s
 => => exporting manifest sha256:c7a0a402d0aa54e07535673cd39ca3ac28cbea7e7bbc2c05  0.0s
 => => exporting config sha256:b35edd994269fea53967fbaa95134a804d362a7104190bc1a9  0.0s
 => => exporting attestation manifest sha256:bb1a7192642cfd1d959086a710a204ce34e9  0.0s
 => => exporting manifest list sha256:9bd3c00622475761ccc1a546f31a3b22b75a9450181  0.0s
 => => naming to docker.io/library/codyssey-web:local                              0.0s
 => => unpacking to docker.io/library/codyssey-web:local                           0.2s
[+] Building 2.4s (7/8)                                                 docker:orbstack
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
 => [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.conf.temp  0.1s
 => [3/3] COPY site/ /usr/share/nginx/html/                                        0.0s
 => exporting to image                                                             0.4s
 => => exporting layers                                                            0.0s
 => => exporting manifest sha256:c7a0a402d0aa54e07535673cd39ca3ac28cbea7e7bbc2c05  0.0s
 => => exporting config sha256:b35edd994269fea53967fbaa95134a804d362a7104190bc1a9  0.0s
 => => exporting attestation manifest sha256:bb1a7192642cfd1d959086a710a204ce34e9  0.0s
 => => exporting manifest list sha256:9bd3c00622475761ccc1a546f31a3b22b75a9450181  0.0s
 => => naming to docker.io/library/codyssey-web:local                              0.0s
 => => unpacking to docker.io/library/codyssey-web:local                           0.3s
[+] Building 2.4s (7/8)                                                 docker:orbstack
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
 => [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.conf.temp  0.1s
 => [3/3] COPY site/ /usr/share/nginx/html/                                        0.0s
 => exporting to image                                                             0.4s
 => => exporting layers                                                            0.0s
 => => exporting manifest sha256:c7a0a402d0aa54e07535673cd39ca3ac28cbea7e7bbc2c05  0.0s
 => => exporting config sha256:b35edd994269fea53967fbaa95134a804d362a7104190bc1a9  0.0s
 => => exporting attestation manifest sha256:bb1a7192642cfd1d959086a710a204ce34e9  0.0s
 => => exporting manifest list sha256:9bd3c00622475761ccc1a546f31a3b22b75a9450181  0.0s
 => => naming to docker.io/library/codyssey-web:local                              0.0s
 => => unpacking to docker.io/library/codyssey-web:local                           0.3s
[+] Building 2.5s (8/8) FINISHED                                        docker:orbstack
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  1.6s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062 1.21kB / 1.21kB  0.6s
 => => sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e4635 19.86MB / 19.86MB  0.7s
 => => sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f 1.40kB / 1.40kB  0.5s
 => => sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f 404B / 404B  0.7s
 => => sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb998 963B / 963B  0.2s
 => => sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e254 627B / 627B  0.2s
 => => sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce 1.90MB / 1.90MB  0.4s
 => => sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a6 4.19MB / 4.19MB  0.4s
 => => extracting sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6d  0.1s
 => => extracting sha256:872998b8576e5aa2dd875c0a156f30bb6bc2573fddce2652fce6884a  0.0s
 => => extracting sha256:87319ffcbc38f43c3b1b33cac15895c5d807a8c8907d8bb6068e2543  0.0s
 => => extracting sha256:0750db6b002e7d071b429e51d22c08a1ee7598ac4dc725a79dbb9985  0.0s
 => => extracting sha256:e10bb963239e76f8e01f42977cf9adc2a56c34afd6b932f52e4b37f7  0.0s
 => => extracting sha256:29fdff62bf433f4391a2e27b3938e1eb083c12d2403ecb06062e6240  0.0s
 => => extracting sha256:cd5ae81ea1c7cd39693d9451176a717fb7b3dbb5588b3eb8c2f28f45  0.0s
 => => extracting sha256:0ecf77f7365c28357ffc7e5dc1e72d8a361ed5c62d47e46354757f57  0.2s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.89kB                                                0.0s
 => [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.conf.temp  0.1s
 => [3/3] COPY site/ /usr/share/nginx/html/                                        0.0s
 => exporting to image                                                             0.4s
 => => exporting layers                                                            0.0s
 => => exporting manifest sha256:c7a0a402d0aa54e07535673cd39ca3ac28cbea7e7bbc2c05  0.0s
 => => exporting config sha256:b35edd994269fea53967fbaa95134a804d362a7104190bc1a9  0.0s
 => => exporting attestation manifest sha256:bb1a7192642cfd1d959086a710a204ce34e9  0.0s
 => => exporting manifest list sha256:9bd3c00622475761ccc1a546f31a3b22b75a9450181  0.0s
 => => naming to docker.io/library/codyssey-web:local                              0.0s
 => => unpacking to docker.io/library/codyssey-web:local                           0.3s
```

</details>

```text
mission_lab % docker images codyssey-web
                                                                    i Info →   U  In Use
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
codyssey-web:local   9bd3c0062247       93.4MB           26MB
```

```text
mission_lab % docker images codyssey-web
                                                                    i Info →   U  In Use
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
codyssey-web:local   9bd3c0062247       93.4MB           26MB
```

```text
mission_lab % ㅑ
zsh: command not found: ㅑ
```

```text
mission_lab % i
zsh: command not found: i
```

<a id="log-08"></a>

### 08. 포트 매핑과 운영 점검

호스트 18080·18081을 컨테이너 8080에 연결하고 HTTP 응답, 로그, 리소스, health 상태를 확인했습니다. 호스트 포트는 격리된 컨테이너 내부 포트에 접근하기 위한 진입점입니다. [접속 화면](evidence/port-18080.png)도 함께 보관돼 있습니다.

```text
mission_lab % docker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:localdocker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:local
0b2e7ac63b2a0ced5f219077b6f9c0cfb43fc7f98ddd4d2eedd1d120a009a620
```

```text
mission_lab % curl -i http://localhost:18080/health
HTTP/1.1 200 OK
Server: nginx/1.30.6
Date: Mon, 02 Nov 2026 08:04:10 GMT
Content-Type: text/plain
Content-Length: 3
Connection: keep-alive
ok
```

```text
mission_lab % curl http://localhost:18080/
```

<details>
<summary>전체 출력 펼치기 (반복 진행률 포함)</summary>

```text
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>개발 워크스테이션 실습</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; background: #f4f3ef; color: #182c28; font: 17px/1.7 system-ui, sans-serif; }
    main { max-width: 760px; margin: 10vh auto; padding: 32px; }
    .label { color: #526a60; font-size: 13px; letter-spacing: .15em; }
    h1 { font-size: clamp(32px, 6vw, 52px); line-height: 1.2; }
    section { border-top: 1px solid #b9c9bf; padding: 20px 0; }
    code { background: #e1e8df; padding: 3px 7px; border-radius: 4px; }
    a { color: #17604d; }
  </style>
</head>
<body>
  <main>
    <p class="label">CODYSSEY / WORKSTATION LAB</p>
    <h1>같은 코드, 같은 실행 환경.</h1>
    <p>직접 만든 NGINX 이미지로 실행한 개발 워크스테이션입니다.</p>
    <section><h2>01 · 포트 연결</h2><p>호스트 포트를 컨테이너의 8080 포트에 연결했습니다. <a href="/health">서버 상태 확인</a></p></section>
    <section><h2>02 · 변경 반영</h2><p>바인드 마운트로 호스트 파일의 변경을 즉시 확인합니다.</p><p id="mount-marker">mount-before</p></section>
    <section><h2>03 · 데이터 유지</h2><p>이름 있는 Docker 볼륨은 컨테이너를 삭제하고 다시 만들어도 데이터를 유지합니다.</p></section>
  </main>
</body>
</html>
```

</details>

```text
mission_lab %
```

```text
mission_lab % curl http://localhost:18080/-i http://localhost:18080/healthdocker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:localcurl -i http://localhost:18080/health                                     curl http://localhost:18080/-i http://localhost:18080/health                                     curl http://localhost:18080/-i http://localhost:18080/healthdocker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:localcurl -i http://localhost:18080/health                                     %                                                                                        dhjung@jeongdahyeui-MacBookAir mission_lab %
```

```text
mission_lab % docker run -d --name codyssey-web-b -p 127.0.0.1:18081:8080 codyssey-web:local
40c5a47a90672ea78c1b878204d6ebb0effc2d88de9d46b16ea280d13b59a1cc
```

```text
mission_lab % curl -i http://localhost:18081/health
HTTP/1.1 200 OK
Server: nginx/1.30.6
Date: Mon, 02 Nov 2026 08:08:21 GMT
Content-Type: text/plain
Content-Length: 3
Connection: keep-alive
ok
```

```text
mission_lab % docker ps
CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS                    PORTS                               NAMES
40c5a47a9067   codyssey-web:local   "/docker-entrypoint.…"   12 seconds ago   Up 11 seconds (healthy)   80/tcp, 127.0.0.1:18081->8080/tcp   codyssey-web-b
0b2e7ac63b2a   codyssey-web:local   "/docker-entrypoint.…"   4 minutes ago    Up 4 minutes (healthy)    80/tcp, 127.0.0.1:18080->8080/tcp   codyssey-web-a
```

```text
mission_lab % docker logs codyssey-web-a
```

<details>
<summary>전체 출력 펼치기 (반복 진행률 포함)</summary>

```text
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/default.conf.template to /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/11/02 08:03:55 [notice] 1#1: using the "epoll" event method
2026/11/02 08:03:55 [notice] 1#1: nginx/1.30.6
2026/11/02 08:03:55 [notice] 1#1: built by gcc 15.2.0 (Alpine 15.2.0)
2026/11/02 08:03:55 [notice] 1#1: OS: Linux 7.2.12-orbstack-00394-gbecdd6130068
2026/11/02 08:03:55 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 20480:1048576
2026/11/02 08:03:55 [notice] 1#1: start worker processes
2026/11/02 08:03:55 [notice] 1#1: start worker process 35
2026/11/02 08:03:55 [notice] 1#1: start worker process 36
2026/11/02 08:03:55 [notice] 1#1: start worker process 37
2026/11/02 08:03:55 [notice] 1#1: start worker process 38
2026/11/02 08:03:55 [notice] 1#1: start worker process 39
2026/11/02 08:03:55 [notice] 1#1: start worker process 40
2026/11/02 08:03:55 [notice] 1#1: start worker process 41
2026/11/02 08:03:55 [notice] 1#1: start worker process 42
192.168.215.1 - - [02/Nov/2026:08:04:16 +0000] "GET / HTTP/1.1" 200 1459 "-" "curl/8.7.1" "-"
192.168.215.1 - - [02/Nov/2026:08:05:09 +0000] "GET / HTTP/1.1" 200 1459 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.144.0 Chrome/150.0.7871.250 Electron/43.8.3 Safari/537.36" "-"
192.168.215.1 - - [02/Nov/2026:08:05:09 +0000] "GET /favicon.ico HTTP/1.1" 404 555 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.144.0 Chrome/150.0.7871.250 Electron/43.8.3 Safari/537.36" "-"
192.168.215.1 - - [02/Nov/2026:08:05:53 +0000] "GET / HTTP/1.1" 200 1459 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36" "-"
192.168.215.1 - - [02/Nov/2026:08:05:53 +0000] "GET /favicon.ico HTTP/1.1" 404 555 "http://localhost:18080/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36" "-"
```

</details>

```text
mission_lab % docker stats --no-stream codyssey-web-a codyssey-web-b
CONTAINER ID   NAME             CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O     PIDS
0b2e7ac63b2a   codyssey-web-a   1.86%     6.824MiB / 7.817GiB   0.09%     6.32kB / 8.65kB   13.5MB / 0B   9
40c5a47a9067   codyssey-web-b   0.00%     6.73MiB / 7.817GiB    0.08%     1.4kB / 632B      9.65MB / 0B   9
```

```text
mission_lab % docker inspect --format '{{.State.Health.Status}}' codyssey-web-a
healthy
```

<a id="log-09"></a>

### 09. 바인드 마운트 변경 전후

18082의 마운트 컨테이너에서는 `mount-before → mount-after`가 반영됐고, 이미지로 실행한 18080에서는 `mount-before`가 유지됐습니다. 원상 복구 명령을 두 번 입력한 기록도 유지했습니다.

```text
mission_lab % docker run -d --name codyssey-mount -p 127.0.0.1:18082:8080 -v "$(pwd)/site:/usr/share/nginx/html:ro" codyssey-web:local
6fe5fa005294373030a5022376c30ce126fd5d63fd02d7fb93be53d40d844a55
```

```text
mission_lab % curl -s http://localhost:18082/ | grep mount-before
    <section><h2>02 · 변경 반영</h2><p>바인드 마운트로 호스트 파일의 변경을 즉시 확인합니다.</p><p id="mount-marker">mount-before</p></section>
```

```text
mission_lab % sed -i '' 's/mount-before/mount-after/g' site/index.html
```

```text
mission_lab % curl -s http://localhost:18082/ | grep mount-after
    <section><h2>02 · 변경 반영</h2><p>바인드 마운트로 호스트 파일의 변경을 즉시 확인합니다.</p><p id="mount-marker">mount-after</p></section>
```

```text
mission_lab % curl -s http://localhost:18080/ | grep mount-before
    <section><h2>02 · 변경 반영</h2><p>바인드 마운트로 호스트 파일의 변경을 즉시 확인합니다.</p><p id="mount-marker">mount-before</p></section>
```

```text
mission_lab % sed -i '' 's/mount-after/mount-before/g' site/index.html
```

```text
mission_lab % sed -i '' 's/mount-after/mount-before/g' site/index.html
```

<a id="log-10"></a>

### 10. 볼륨 영속성과 리소스 정리

볼륨에 `persistent-data`를 쓰고 writer 컨테이너 삭제 후 새 컨테이너에서 같은 값을 읽었습니다. 마지막에는 실습 컨테이너와 볼륨을 정리했습니다.

```text
mission_lab % docker volume create codyssey-practice-data docker volume create codyssey-practice-data
codyssey-practice-data
```

```text
mission_lab % docker volume ls
DRIVER    VOLUME NAME
local     codyssey-practice-data
```

```text
mission_lab % docker run -it --name codyssey-writer -v codyssey-practice-data:/data ubuntu:24.04 bash
root@de7fe8831960:/# echo "persistent-data" > /data/message.txt
root@de7fe8831960:/# cat /data/message.txt
persistent-data
root@de7fe8831960:/# exit
exit
```

```text
mission_lab % docker rm codyssey-writer
codyssey-writer
```

```text
mission_lab % docker run --rm -v codyssey-practice-data:/data ubuntu:24.04 cat /data/message.txt
persistent-data
```

```text
mission_lab % docker stop codyssey-web-a codyssey-web-b codyssey-mount
codyssey-web-a
codyssey-web-b
codyssey-mount
```

```text
mission_lab % docker rm codyssey-web-a codyssey-web-b codyssey-mount
codyssey-web-a
codyssey-web-b
codyssey-mount
```

```text
mission_lab % docker volume rm codyssey-practice-data
codyssey-practice-data
```

<a id="log-11"></a>

### 11. Compose 실행과 환경 변수

[compose.yaml](compose.yaml)로 `up`, `ps`, `logs`, `down`을 수행했습니다. `HOST_PORT=18083 NGINX_PORT=9090`으로 포트를 바꾼 뒤에도 `/health`가 `ok`를 반환했습니다.

```text
mission_lab % cat compose.yaml
cat: compose.yaml: No such file or directory
```

```text
mission_lab % cat compose.yaml
name: codyssey-workstation-lab
services:
  web:
    build: .
    ports:
      - "127.0.0.1:${HOST_PORT:-18080}:${NGINX_PORT:-8080}"
    environment:
      NGINX_PORT: ${NGINX_PORT:-8080}
    volumes:
      - ./site:/usr/share/nginx/html:ro
    restart: unless-stopped
```

```text
mission_lab %
```

```text
mission_lab % clear
```

```text
mission_lab % docker compose up -d --build --wait
```

<details>
<summary>전체 출력 펼치기 (반복 진행률 포함)</summary>

```text
[+] Building 0.0s (0/1)
 => [internal] load local bake definitions                                         0.0s
[+] Building 0.1s (1/2)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
[+] Building 0.3s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.2s
[+] Building 0.4s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.3s
[+] Building 0.6s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.5s
[+] Building 0.7s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.6s
[+] Building 0.9s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.8s
[+] Building 1.0s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             0.9s
[+] Building 1.2s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.1s
[+] Building 1.3s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.2s
[+] Building 1.5s (2/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.4s
[+] Building 1.5s (3/3)
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.4s
[+] Building 1.7s (8/9)
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.60kB                                                0.0s
 => CACHED [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.co  0.0s
 => CACHED [3/3] COPY site/ /usr/share/nginx/html/                                 0.0s
 => exporting to image                                                             0.1s
 => => exporting layers                                                            0.0s
 => => exporting manifest sha256:e07fd3b1900c981adc4f7e6d11a129521f544af1bc9204f1  0.0s
 => => exporting config sha256:bea9276a9e070adcd6ba64948dd966c618d046bc743ac7bcbc  0.0s
 => => exporting attestation manifest sha256:35fd55135aaad0207b1950a9afee43fd9532  0.0s
 => => exporting manifest list sha256:36fbc7feb568379b540637a9ddc7f041c7ffea47c30  0.0s
[+] Building 1.8s (9/10)
 => => transferring context: 1.60kB                                                0.0s
 => CACHED [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.co  0.0s
 => CACHED [3/3] COPY site/ /usr/share/nginx/html/                                 0.0s
 => exporting to image                                                             0.1s
 => => exporting layers                                                            0.0s
 => => exporting manifest sha256:e07fd3b1900c981adc4f7e6d11a129521f544af1bc9204f1  0.0s
 => => exporting config sha256:bea9276a9e070adcd6ba64948dd966c618d046bc743ac7bcbc  0.0s
 => => exporting attestation manifest sha256:35fd55135aaad0207b1950a9afee43fd9532  0.0s
 => => exporting manifest list sha256:36fbc7feb568379b540637a9ddc7f041c7ffea47c30  0.0s
 => => naming to docker.io/library/codyssey-workstation-lab-web:latest             0.0s
 => => unpacking to docker.io/library/codyssey-workstation-lab-web:latest          0.0s
 => resolving provenance for metadata file                                         0.0s
[+] Building 1.8s (10/10) FINISHED
 => [internal] load local bake definitions                                         0.0s
 => => reading from stdin 542B                                                     0.0s
 => [internal] load build definition from Dockerfile                               0.0s
 => => transferring dockerfile: 415B                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:stable-alpine             1.4s
 => [internal] load .dockerignore                                                  0.0s
 => => transferring context: 2B                                                    0.0s
 => [1/3] FROM docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => => resolve docker.io/library/nginx:stable-alpine@sha256:0e52bd054126cdc040b12  0.0s
 => [internal] load build context                                                  0.0s
 => => transferring context: 1.60kB                                                0.0s
 => CACHED [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.co  0.0s
 => CACHED [3/3] COPY site/ /usr/share/nginx/html/                                 0.0s
 => exporting to image                                                             0.1s
 => => exporting layers                                                            0.0s
 => => exporting manifest sha256:e07fd3b1900c981adc4f7e6d11a129521f544af1bc9204f1  0.0s
 => => exporting config sha256:bea9276a9e070adcd6ba64948dd966c618d046bc743ac7bcbc  0.0s
 => => exporting attestation manifest sha256:35fd55135aaad0207b1950a9afee43fd9532  0.0s
 => => exporting manifest list sha256:36fbc7feb568379b540637a9ddc7f041c7ffea47c30  0.0s
 => => naming to docker.io/library/codyssey-workstation-lab-web:latest             0.0s
 => => unpacking to docker.io/library/codyssey-workstation-lab-web:latest          0.0s
 => resolving provenance for metadata file                                         0.0s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Starting                                0.1s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 0.2s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 0.3s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 0.4s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 0.5s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 0.6s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 0.7s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 0.8s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 0.9s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 1.0s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 1.1s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 1.2s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 1.3s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 1.4s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 1.5s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 1.6s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 1.7s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 1.8s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 1.9s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 2.0s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 2.1s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 2.2s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 2.3s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 2.4s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 2.5s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 2.6s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 2.7s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 2.8s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 2.9s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 3.0s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 3.1s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 3.2s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 3.3s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 3.4s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 3.5s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 3.6s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 3.7s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 3.8s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 3.9s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 4.0s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 4.1s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 4.2s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 4.3s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 4.4s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 4.5s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 4.6s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 4.7s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 4.8s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 4.9s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 5.0s
[+] up 2/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 5.1s
[+] up 3/3
 ✔ Image codyssey-workstation-lab-web       Built                                   1.8s
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ✔ Container codyssey-workstation-lab-web-1 Healthy                                 5.1s
```

</details>

```text
mission_lab % docker compose up -d --build --waitclear                         cat compose.yamlclear      docker compose up -d --build --wait                                   docker compose ps
NAME                             IMAGE                          COMMAND                  SERVICE   CREATED          STATUS                    PORTS
codyssey-workstation-lab-web-1   codyssey-workstation-lab-web   "/docker-entrypoint.…"   web       19 seconds ago   Up 19 seconds (healthy)   80/tcp, 127.0.0.1:18080->8080/tcp
```

```text
mission_lab % docker compose ps
NAME                             IMAGE                          COMMAND                  SERVICE   CREATED          STATUS                    PORTS
codyssey-workstation-lab-web-1   codyssey-workstation-lab-web   "/docker-entrypoint.…"   web       33 seconds ago   Up 33 seconds (healthy)   80/tcp, 127.0.0.1:18080->8080/tcp
```

```text
mission_lab % curl http://localhost:18080/health
ok
```

```text
mission_lab % docker compose logs --tail 20 web
web-1  | 10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
web-1  | /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
web-1  | /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
web-1  | 20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/default.conf.template to /etc/nginx/conf.d/default.conf
web-1  | /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
web-1  | /docker-entrypoint.sh: Configuration complete; ready for start up
web-1  | 2026/11/02 08:41:39 [notice] 1#1: using the "epoll" event method
web-1  | 2026/11/02 08:41:39 [notice] 1#1: nginx/1.30.6
web-1  | 2026/11/02 08:41:39 [notice] 1#1: built by gcc 15.2.0 (Alpine 15.2.0)
web-1  | 2026/11/02 08:41:39 [notice] 1#1: OS: Linux 7.2.12-orbstack-00394-gbecdd6130068
web-1  | 2026/11/02 08:41:39 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 20480:1048576
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker processes
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 35
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 36
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 37
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 38
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 39
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 40
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 41
web-1  | 2026/11/02 08:41:39 [notice] 1#1: start worker process 42
```

```text
mission_lab % docker compose down
[+] down 0/1
 ⠋ Container codyssey-workstation-lab-web-1 Stopping                                0.1s
[+] down 0/1
 ⠙ Container codyssey-workstation-lab-web-1 Stopping                                0.2s
[+] down 1/2
 ✔ Container codyssey-workstation-lab-web-1 Removed                                 0.2s
 ⠋ Network codyssey-workstation-lab_default Removing                                0.0s
[+] down 2/2
 ✔ Container codyssey-workstation-lab-web-1 Removed                                 0.2s
 ✔ Network codyssey-workstation-lab_default Removed                                 0.1s
```

```text
mission_lab % HOST_PORT=18083 NGINX_PORT=9090 docker compose up -d --wait
```

<details>
<summary>전체 출력 펼치기 (반복 진행률 포함)</summary>

```text
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Creating                                0.0s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Starting                                0.1s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 0.2s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 0.3s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 0.4s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 0.5s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 0.6s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 0.7s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 0.8s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 0.9s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 1.0s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 1.1s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 1.2s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 1.3s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 1.4s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 1.5s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 1.6s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 1.7s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 1.8s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 1.9s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 2.0s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 2.1s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 2.2s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 2.3s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 2.4s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 2.5s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 2.6s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 2.7s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 2.8s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 2.9s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 3.0s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 3.1s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 3.2s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 3.3s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 3.4s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 3.5s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 3.6s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 3.7s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 3.8s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 3.9s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 4.0s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 4.1s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠹ Container codyssey-workstation-lab-web-1 Waiting                                 4.2s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠸ Container codyssey-workstation-lab-web-1 Waiting                                 4.3s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠼ Container codyssey-workstation-lab-web-1 Waiting                                 4.4s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠴ Container codyssey-workstation-lab-web-1 Waiting                                 4.5s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠦ Container codyssey-workstation-lab-web-1 Waiting                                 4.6s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠧ Container codyssey-workstation-lab-web-1 Waiting                                 4.7s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠇ Container codyssey-workstation-lab-web-1 Waiting                                 4.8s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠏ Container codyssey-workstation-lab-web-1 Waiting                                 4.9s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠋ Container codyssey-workstation-lab-web-1 Waiting                                 5.0s
[+] up 1/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ⠙ Container codyssey-workstation-lab-web-1 Waiting                                 5.1s
[+] up 2/2
 ✔ Network codyssey-workstation-lab_default Created                                 0.0s
 ✔ Container codyssey-workstation-lab-web-1 Healthy                                 5.1s
```

</details>

```text
mission_lab % curl http://localhost:18083/health
ok
```

```text
mission_lab % HOST_PORT=18083 NGINX_PORT=9090 docker compose down
[+] down 0/1
 ⠋ Container codyssey-workstation-lab-web-1 Stopping                                0.1s
[+] down 1/2
 ✔ Container codyssey-workstation-lab-web-1 Removed                                 0.2s
 ⠋ Network codyssey-workstation-lab_default Removing                                0.0s
[+] down 2/2
 ✔ Container codyssey-workstation-lab-web-1 Removed                                 0.2s
 ✔ Network codyssey-workstation-lab_default Removed                                 0.0s
```

```text
mission_lab % exit
```

## 트러블슈팅 기록

| 문제 | 원인 가설 | 로그에서 확인한 내용 | 해결·대안 및 확인 한계 |
| --- | --- | --- | --- |
| `dockr images` 실행 실패 | `docker` 철자 오타 | `command not found: dockr` | `docker images` 재입력 후 이미지 목록 출력 (04절) |
| `cat Dockerfile` 실패 | 현재 위치에 파일이 아직 없음 | `No such file or directory` | 이후 같은 명령으로 Dockerfile 내용 확인. 파일 생성 과정은 이 로그에 없음 (07절) |
| `code ~/.zshrc` 실행 실패 | VS Code CLI가 PATH에 없을 가능성 | 같은 오류가 두 번 발생 | 이후 오류 없는 재시도 기록. 구체적 설정 변경은 확인 불가 (06절) |

## 입력 과정 기록

<details>
<summary>입력 중 오타·삭제·붙여넣기·재입력 흔적 펼치기</summary>

`⌫`는 백스페이스, `⏎`는 캐리지 리턴, `␇`는 터미널 벨입니다. `L숫자`는 원본 로그의 줄 번호입니다. 색상과 커서 이동 제어 코드는 표시에서 제외했으며, 지웠던 글자 자체는 그대로 남겼습니다. 여기의 중복 문자열에는 실제 재입력뿐 아니라 셸의 화면 재표시도 포함됩니다.

```text
L1 | mission_lab % sw_vers⌫⌫⌫⌫⌫⌫⌫sw_vers⏎⏎
L6 | mission_lab % echo "$SHELL"echo "$SHELL"⏎⏎
L8 | mission_lab % echo "${TERM_PROGRAM:-unknown}"echo "${TERM_PROGRAM:-unknown}"⏎⏎
L10 | mission_lab % g⌫git 00v⌫ ⌫⌫ ⌫⌫ ⌫--version⏎⏎
L12 | mission_lab % d⌫docker --version⏎⏎
L14 | mission_lab % docker info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}} Architecture={{.Architecture}} Driver={{.Driver}}'docker info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}} Architecture={{.Architecture}} Driver={{.Driver}}'⏎⏎
L16 | mission_lab % docker compose versiondocker compose version⏎⏎
L18 | mission_lab % ㅁㅡ⌫⌫  ⌫⌫⌫⌫  ⌫⌫m⌫mkdir -p practive⌫ ⌫⌫ ⌫ce⏎⏎
L19 | mission_lab % c⌫cd practice/⌫ ⌫⏎⏎
L20 | practice % t⌫tou⌫ ⌫⌫⌫t ⌫⌫ ⌫t⌫touch⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫t ⌫⌫ ⌫t⌫tou==⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫t ⌫⌫ ⌫t⌫touch m⌫ ⌫empth.txt⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫y.txt⏎⏎
L21 | practice % echo "Hello terminal" > original.txtecho "Hello terminal" > original.txt⏎⏎
L22 | practice % c⌫cat original.txt ⌫ ⌫⏎⏎
L24 | practice % cp original.txt copy.txtcp original.txt copy.txt⏎⏎
L25 | practice % mv copy.txt renamed.txtmv copy.txt renamed.txt⏎⏎
L26 | practice % mkdir -p archivemkdir -p archive⏎⏎
L27 | practice % mv renamed.txt archive/mv renamed.txt archive/⏎⏎
L28 | practice % ls -la archivels -la archive⏎⏎
L33 | practice % rm archive/renamed.txtrm archive/renamed.txt⏎⏎
L34 | practice % rmdir archivermdir archive⏎⏎
L35 | practice % mkdir -p permissionsmkdir -p permissions⏎⏎
L36 | practice % chmod 600 original.txtchmod 600 original.txt⏎⏎
L37 | practice % chmod 700 permissionschmod 700 permissions⏎⏎
L38 | practice % ls -ld original.txt permissionsls -ld original.txt permissions⏎⏎
L41 | practice % chmod 644 original.txtchmod 644 original.txt⏎⏎
L42 | practice % chmod 755 permissionschmod 755 permissions⏎⏎
L43 | practice % ls -ld original.txt permissionsls -ld original.txt permissions⏎⏎
L46 | practice % ㅊㅇ .⌫ ⌫⌫⌫⌫  ⌫⌫⌫⌫  ⌫⌫c⌫cd ..⏎⏎
L47 | mission_lab % l⌫ls⏎⏎
L49 | mission_lab % c⌫clear⏎⏎
L50 | mission_lab % docker pull hello-world:latestdocker pull hello-world:latest⏎⏎
L57 | mission_lab % 애ㅊ⌫⌫  ⌫⌫⌫⌫  ⌫⌫d⌫dockr images⏎⏎
L59 | mission_lab % d⌫docker images⏎⏎
L63 | mission_lab % docker run --name codyssey-hello hello-world:latestdocker run --name codyssey-hello hello-world:latest⏎⏎
L86 | mission_lab % d⌫docker ps⏎⏎
L88 | mission_lab % d⌫docker ps -a⏎⏎
L91 | mission_lab % d⌫docker logs doc⌫ ⌫d⌫ ⌫⌫ ⌫⌫ ⌫codyssey_1⌫ ⌫test1⏎⏎
L93 | mission_lab % docker logs codyssey_test1⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫␇␇␇-⌫ ⌫⌫ ⌫-␇␇hello⏎⏎
L116 | mission_lab % docker rm codyssey-hellodocker rm codyssey-hello⏎⏎
L118 | mission_lab % docker pull ubuntu:24.04docker pull ubuntu:24.04⏎⏎
L125 | mission_lab % docker run -it --name codyssey-ubuntu ubuntu:24.04 bashdocker run -it --name codyssey-ubuntu ubuntu:24.04 bash⏎⏎
L150 | mission_lab % d⌫docker ps -a⏎⏎
L153 | mission_lab % docker start -ai codyssey-ubuntudocker start -ai codyssey-ubuntu⏎⏎
L156 | mission_lab % docker rm codyssey-ubuntudocker rm codyssey-ubuntu]⌫ ⌫⏎⏎
L158 | mission_lab % docker run -d --name codyssey-keep ubuntu:24.04 sleep infinitydocker run -d --name codyssey-keep ubuntu:24.04 sleep infinity⏎⏎
L160 | mission_lab % docker exec -it codyssey-keep bashdocker exec -it codyssey-keep bash⏎⏎
L163 | mission_lab % c⌫cod⌫ ⌫⌫⌫c ⌫⌫ ⌫d⌫docker ps⏎⏎
L166 | mission_lab % d⌫do⌫⌫d ⌫⌫ ⌫d⌫docker sp⌫ ⌫op⌫ ⌫⌫ ⌫top do⌫ ⌫⌫ ⌫cod␇␇yssey-=⌫ ⌫keep ⌫⏎⏎
L168 | mission_lab % echo $SHELLecho $SHELL⏎⏎
L170 | mission_lab % 애찯ㄱ⌫⌫  ⌫⌫⌫⌫  ⌫⌫⌫⌫  ⌫⌫d⌫docker stop d⌫ ⌫co␇␇⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫ ⌫tar␇␇t ␇⏎⏎
L173 | mission_lab % ㅣㄴ⏎⏎
L175 | mission_lab % l⌫ls⏎⏎
L177 | mission_lab % docker completion zsh > ~/.zsh/completions/_dockerdocker completion zsh > ~/.zsh/completions/_docker⏎⏎
L178 | mission_lab % code ~/.zshrccode ~/.zshrc⏎⏎
L180 | mission_lab % code ~/.zshrccode ~/.zshrc⏎⏎
L182 | mission_lab % 챙채ㅊㅊ⌫⌫  ⌫⌫⌫⌫  ⌫⌫⌫⌫  ⌫⌫⌫⌫  ⌫⌫code ~/.zshrc⏎⏎
L183 | mission_lab % 칟ㅁㄱ⌫⌫  ⌫⌫⌫⌫  ⌫⌫⌫⌫  ⌫⌫c⌫clear⏎⏎
L184 | mission_lab % c⌫codker⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫c ⌫⌫ ⌫d⌫docker ps -a⏎⏎
L186 | mission_lab % d⌫docker p⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫d ⌫⌫ ⌫docker ps -a⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫d ⌫⌫ ⌫⏎⏎
L187 | mission_lab % ⏎⏎
L188 | mission_lab % ⏎⏎
L189 | mission_lab % cat Dockerfilecat Dockerfile⏎⏎
L191 | mission_lab % cat Dockerfile⏎⏎
L199 | mission_lab % cat nginx/default.conf.templatecat nginx/default.conf.template⏎⏎
L201 | mission_lab % ⏎⏎
L202 | mission_lab % ⏎⏎
L203 | mission_lab % cat nginx/default.conf.templatecat nginx/default.conf.template⏎⏎
L216 | mission_lab % docker build -t codyssey-web:local .docker build -t codyssey-web:local .⏎⏎
L308 | mission_lab % docker build -t codyssey-web:local .⏎⏎
L573 | mission_lab % docker images codyssey-webdocker images codyssey-web⏎⏎
L577 | mission_lab % docker images codyssey-web⏎⏎
L581 | mission_lab % ㅑ⏎⏎
L583 | mission_lab % i⏎⏎
L585 | mission_lab % i⌫ ⌫v⌫ ⌫docker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:localdocker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:local⏎⏎
L587 | mission_lab % curl -i http://localhost:18080/healthcurl -i http://localhost:18080/health⏎⏎
L596 | mission_lab % curl http://localhost:18080/curl http://localhost:18080/⏎⏎
L625 | mission_lab % ⏎⏎
L626 | mission_lab % curl http://localhost:18080/-i http://localhost:18080/healthdocker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:localcurl -i http://localhost:18080/health⏎                                     curl http://localhost:18080/-i http://localhost:18080/health                                     curl http://localhost:18080/-i http://localhost:18080/healthdocker run -d --name codyssey-web-a -p 127.0.0.1:18080:8080 codyssey-web:localcurl -i http://localhost:18080/health⏎                                     ⏎%                                                                                       ⏎ ⏎⏎dhjung@jeongdahyeui-MacBookAir mission_lab % ⏎⏎
L627 | mission_lab % docker run -d --name codyssey-web-b -p 127.0.0.1:18081:8080 codyssey-web:localdocker run -d --name codyssey-web-b -p 127.0.0.1:18081:8080 codyssey-web:local⏎⏎
L629 | mission_lab % curl -i http://localhost:18081/healthcurl -i http://localhost:18081/health⏎⏎
L638 | mission_lab % docker psdocker ps⏎⏎
L642 | mission_lab % docker logs codyssey-web-adocker logs codyssey-web-a⏎⏎
L672 | mission_lab % docker stats --no-stream codyssey-web-a codyssey-web-bdocker stats --no-stream codyssey-web-a codyssey-web-b⏎⏎
L676 | mission_lab % docker inspect --format '{{.State.Health.Status}}' codyssey-web-adocker inspect --format '{{.State.Health.Status}}' codyssey-web-a⏎⏎
L678 | mission_lab % docker run -d --name codyssey-mount -p 127.0.0.1:18082:8080 -v "$(pwd)/site:/usr/share/nginx/html:ro" codyssey-web:localdocker run -d --name codyssey-mount -p 127.0.0.1:18082:8080 -v "$(pwd)/site:/usr/share/nginx/html:ro" codyssey-web:local⏎⏎
L680 | mission_lab % curl -s http://localhost:18082/ | grep mount-beforecurl -s http://localhost:18082/ | grep mount-before⏎⏎
L682 | mission_lab % sed -i '' 's/mount-before/mount-after/g' site/index.htmlsed -i '' 's/mount-before/mount-after/g' site/index.html⏎⏎
L683 | mission_lab % curl -s http://localhost:18082/ | grep mount-aftercurl -s http://localhost:18082/ | grep mount-after⏎⏎
L685 | mission_lab % curl -s http://localhost:18080/ | grep mount-beforecurl -s http://localhost:18080/ | grep mount-before⏎⏎
L687 | mission_lab % sed -i '' 's/mount-after/mount-before/g' site/index.htmlsed -i '' 's/mount-after/mount-before/g' site/index.html⏎⏎
L688 | mission_lab % sed -i '' 's/mount-after/mount-before/g' site/index.htmlsed -i '' 's/mount-after/mount-before/g' site/index.html⏎⏎
L689 | mission_lab %  ⌫ ph⌫ ⌫⌫⌫  ⌫⌫docker volume create codyssey-practice-data ⏎docker volume create codyssey-practice-data ⏎⏎⏎
L691 | mission_lab % docker volume lsdocker volume ls⏎⏎
L694 | mission_lab % docker run -it --name codyssey-writer -v codyssey-practice-data:/data ubuntu:24.04 bashdocker run -it --name codyssey-writer -v codyssey-practice-data:/data ubuntu:24.04 bash⏎⏎
L700 | mission_lab % docker rm codyssey-writerdocker rm codyssey-writer⏎⏎
L702 | mission_lab % docker run --rm -v codyssey-practice-data:/data ubuntu:24.04 cat /data/message.txtdocker run --rm -v codyssey-practice-data:/data ubuntu:24.04 cat /data/message.txt⏎⏎
L704 | mission_lab % docker stop codyssey-web-a codyssey-web-b codyssey-mountdocker stop codyssey-web-a codyssey-web-b codyssey-mount⏎⏎
L708 | mission_lab % docker rm codyssey-web-a codyssey-web-b codyssey-mountdocker rm codyssey-web-a codyssey-web-b codyssey-mount⏎⏎
L712 | mission_lab % docker volume rm codyssey-practice-datadocker volume rm codyssey-practice-data⏎⏎
L714 | mission_lab % cat compose.yamlcat compose.yaml⏎⏎
L716 | mission_lab % cat compose.yaml⏎⏎
L728 | mission_lab % docker compose up -d --build --waitdocker compose up -d --build --wait\⌫ ⌫t⌫ ⌫t⌫␇⌫ ⌫␇⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫ ⌫⌫⌫d ⌫⌫ ⌫⏎⏎
L729 | mission_lab % c⌫clear⏎⏎
L730 | mission_lab % docker compose up -d --build --waitdocker compose up -d --build --wait⏎⏎
L1053 | mission_lab % docker compose up -d --build --waitclear                              ⌫⌫⌫⌫⌫cat compose.yamlclear           ⌫⌫⌫⌫⌫docker compose up -d --build --wait                                   c⌫codk⌫ ⌫⌫ ⌫⌫⌫c ⌫⌫ ⌫d⌫docker compose ps⏎⏎
L1056 | mission_lab % docker compose ps⏎⏎
L1059 | mission_lab % curl http://localhost:18080/healthcurl http://localhost:18080/health⏎⏎
L1061 | mission_lab % docker compose logs --tail 20 webdocker compose logs --tail 20 web⏎⏎
L1082 | mission_lab % docker compose downdocker compose down⏎⏎
L1093 | mission_lab % HOST_PORT=18083 NGINX_PORT=9090 docker compose up -d --waitHOST_PORT=18083 NGINX_PORT=9090 docker compose up -d --wait⏎⏎
L1253 | mission_lab % curl http://localhost:18083/healthcurl http://localhost:18083/health⏎⏎
L1255 | mission_lab % HOST_PORT=18083 NGINX_PORT=9090 docker compose downHOST_PORT=18083 NGINX_PORT=9090 docker compose down⏎⏎
L1264 | mission_lab % e⌫exit⏎⏎
```

</details>
