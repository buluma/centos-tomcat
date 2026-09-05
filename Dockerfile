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

# Trust anchor: SHA-256 digest of the official Tomcat 10 release-manager KEYS file
# (https://downloads.apache.org/tomcat/tomcat-10/KEYS). Change deliberately only
# when the Apache Tomcat 10 signing keys are legitimately rotated.
ARG TOMCAT_KEYS_SHA256=850f793865c1b4a64ba505429702e32a20d71a3accb81b34fb3bf9989af7c83c

RUN dnf -y install gnupg2 && \
    cd /tmp && \
    wget https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    wget -O apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 && \
    wget -O apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc && \
    wget -O KEYS https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS && \
    echo "${TOMCAT_KEYS_SHA256}  KEYS" | sha256sum -c - && \
    gpg --batch --import KEYS && \
    sha512sum -c apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 && \
    gpg --batch --verify apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    SIGKEYID="$(gpg --batch --status-fd=1 --verify apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc apache-tomcat-${TOMCAT_VERSION}.tar.gz 2>/dev/null | awk '/^\[GNUPG:\] GOODSIG /{print $3; exit}')" && \
    SIGNER="$(gpg --list-keys --with-colons | awk -F: -v id="$SIGKEYID" '/^pub/{primary=""} /^fpr/ && primary=="" {primary=$10} /^sub/ && $5==id {print primary; exit}')" && \
    case "$SIGNER" in \
        5C3C5F3E314C866292F359A8F3AD5C94A67F707E|A9C5DF4D22E99998D9875A5110C01C5A2F6059E7) ;; \
        *) echo "GPG signature not made by an allowed Tomcat release manager: $SIGNER" >&2; exit 1 ;; \
    esac && \
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
