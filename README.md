# Rocky Linux Tomcat

[![Docker Image CI](https://github.com/buluma/centos-tomcat/actions/workflows/build.yml/badge.svg)](https://github.com/buluma/centos-tomcat/actions/workflows/build.yml)

This image is based on Rocky Linux 8 and includes Eclipse Temurin 17 and Apache Tomcat 10.1.60. Published images support `linux/amd64` and `linux/arm64`.

## Published images

Images are published to Docker Hub and GitHub Container Registry with the `latest` and `10.1.60` tags.

```sh
docker pull buluma/centos-tomcat:10.1.60
# Or:
docker pull ghcr.io/buluma/centos-tomcat:10.1.60
```

## Build locally

```sh
git clone https://github.com/buluma/centos-tomcat.git
cd centos-tomcat
docker build -t centos-tomcat:local .
```

## Deploy a WAR file

Start the image, copy your WAR into Tomcat's deployment directory, and open port 8080:

```sh
docker run -d --name centos-tomcat -p 8080:8080 buluma/centos-tomcat:10.1.60
docker cp /path/to/your-app.war centos-tomcat:/opt/tomcat/webapps/
```

Open [http://localhost:8080](http://localhost:8080). Follow the container output with `docker logs -f centos-tomcat`. Stop and restart it with `docker stop centos-tomcat` and `docker start centos-tomcat`; remove it with `docker rm -f centos-tomcat`.

## Image contents

| Component | Version |
|:--|:--|
| Base image | Rocky Linux 8 |
| Java | Eclipse Temurin 17 |
| Apache Tomcat | [10.1.60](https://tomcat.apache.org/download-10.cgi) |
| Platforms | `linux/amd64`, `linux/arm64` |

Tomcat 10 uses Jakarta EE APIs (`jakarta.*`). Applications built for Tomcat 9 or earlier may need migration before they will run.

[The official Apache Tomcat image](https://github.com/docker-library/tomcat) is also available.
