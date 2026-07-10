# Centos based container with Java and Tomcat
FROM rockylinux:8
MAINTAINER buluma

# Install prepare infrastructure
RUN dnf -y update &&  dnf -y install wget tar

# Prepare environment 
ENV JAVA_HOME /usr/java/latest
ENV CATALINA_HOME /opt/tomcat 
ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin:$CATALINA_HOME/scripts

# Install Eclipse Temurin JDK 17
RUN dnf -y install tar &&     curl -o /tmp/jdk17.rpm -L "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.14%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.14_7.rpm" &&     dnf -y localinstall /tmp/jdk17.rpm &&     rm -f /tmp/jdk17.rpm &&     java -version

ENV JAVA_HOME /usr/lib/jvm/temurin-17-jdk

# Install Tomcat
ENV TOMCAT_MAJOR 10
ENV TOMCAT_VERSION 10.0.16

RUN wget http://mirror.linux-ia64.org/apache/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz &&  tar -xvf apache-tomcat-${TOMCAT_VERSION}.tar.gz &&  rm apache-tomcat*.tar.gz &&  mv apache-tomcat* ${CATALINA_HOME}

RUN chmod +x ${CATALINA_HOME}/bin/*sh

# Create Tomcat admin user
ADD create_admin_user.sh $CATALINA_HOME/scripts/create_admin_user.sh
ADD tomcat.sh $CATALINA_HOME/scripts/tomcat.sh
RUN chmod +x $CATALINA_HOME/scripts/*.sh

# Create tomcat user
RUN groupadd -r tomcat &&  useradd -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin  -c "Tomcat user" tomcat &&  chown -R tomcat:tomcat ${CATALINA_HOME}

WORKDIR /opt/tomcat

EXPOSE 8080
EXPOSE 8009

USER tomcat
CMD ["tomcat.sh"]
