# Rocky Linux based container with Java and Tomcat
FROM rockylinux:8
MAINTAINER buluma

# Install prepare infrastructure
RUN dnf -y update &&  dnf -y install wget tar

# Prepare environment 
ENV CATALINA_HOME /opt/tomcat

# Install Eclipse Temurin JDK 17 from Adoptium API
RUN dnf -y install tar curl &&     curl -o /tmp/jdk17.tar.gz -L "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse" &&     tar -xzf /tmp/jdk17.tar.gz -C /usr/local/ &&     mv /usr/local/jdk-* /usr/local/jdk17 &&     rm -f /tmp/jdk17.tar.gz &&     ln -s /usr/local/jdk17/bin/java /usr/bin/java

ENV JAVA_HOME /usr/local/jdk17
ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin:$CATALINA_HOME/scripts

# Install Tomcat
ENV TOMCAT_MAJOR 10
ENV TOMCAT_VERSION 10.1.59

RUN dnf -y install gnupg2 && \
    cd /tmp && \
    wget https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    wget -O apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 && \
    wget -O apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc && \
    sha512sum -c apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 && \
    wget -O KEYS https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS && \
    gpg --batch --import KEYS && \
    gpg --batch --verify apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    tar -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    rm -f apache-tomcat-*.tar.gz* KEYS && \
    mv apache-tomcat* ${CATALINA_HOME}

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
