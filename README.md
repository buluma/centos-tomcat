# Centos Tomcat

[![Docker Image CI](https://github.com/buluma/centos-tomcat/actions/workflows/build.yml/badge.svg)](https://github.com/buluma/centos-tomcat/actions/workflows/build.yml)

Docker container: CentOS 8 + Java 17 + Tomcat 10

## Build the image

```sh
git clone https://github.com/buluma/centos-tomcat.git
cd centos-tomcat
docker build -t buluma/centos-tomcat .
```

## How to use
Put your war under the `/opt/tomcat/webapps` directory and run the following command.

```sh
docker run -v /opt/tomcat/webapps:/opt/tomcat/webapps -v /opt/tomcat/logs:/opt/tomcat/logs -p 8080:8080 -i -t --name centos-tomcat buluma/centos-tomcat
```

Once you run it, you can start the container with `docker start centos-tomcat` in next time and log file will be under the `/opt/tomcat/logs` directory.

Also, if you got some error, you can remove the container with `docker rm centos-tomcat`. Your current container list will be show with `docker ps -a`.

For Mac user, you must share the directory `/opt/tomcat/webapps` and `/opt/tomcat/logs` on Docker > Preferences > File Sharing.

## Versions
If you got error while build the docker image, please check the latest version of Java and Tomcat.

|Software|Version|Note|
|:-----------|:------------|:------------|
|CentOS|8||
|Java|17 [Java Release Note](https://jdk.java.net/17/release-notes)|
|Apache Tomcat|10.0.16|[Tomcat Download Page](https://tomcat.apache.org/download-10.cgi)|

[Docker Official Image for Tomcat](https://github.com/docker-library/tomcat) is also available.
