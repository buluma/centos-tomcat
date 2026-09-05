# Rocky Linux based container with Java and Tomcat
FROM rockylinux:8
LABEL org.opencontainers.image.authors="buluma"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install prepare infrastructure
RUN dnf -y update &&  dnf -y install wget-1.19.5-16.el8_10 tar-1.30-11.el8_10 &&  dnf -y clean all &&  rm -rf /var/cache/dnf

# Prepare environment 
ENV CATALINA_HOME=/opt/tomcat

# Install Eclipse Temurin JDK 17 from Adoptium API
RUN wget -q -O /tmp/jdk17.tar.gz "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse" &&     tar -xzf /tmp/jdk17.tar.gz -C /usr/local/ &&     mv /usr/local/jdk-* /usr/local/jdk17 &&     rm -f /tmp/jdk17.tar.gz &&     ln -s /usr/local/jdk17/bin/java /usr/bin/java

ENV JAVA_HOME=/usr/local/jdk17
ENV PATH=$PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin:$CATALINA_HOME/scripts

# Install Tomcat
ENV TOMCAT_MAJOR=10 \
    TOMCAT_VERSION=10.1.59

# Trust anchor: SHA-256 digest of the official Tomcat 10 release-manager KEYS file
# (https://downloads.apache.org/tomcat/tomcat-10/KEYS). Change deliberately only
# when the Apache Tomcat 10 signing keys are legitimately rotated.
ARG TOMCAT_KEYS_SHA256=850f793865c1b4a64ba505429702e32a20d71a3accb81b34fb3bf9989af7c83c

WORKDIR /tmp

RUN dnf -y install gnupg2-2.2.20-4.el8_10 &&  dnf -y clean all &&  rm -rf /var/cache/dnf && \
    wget -q https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    wget -q -O apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 && \
    wget -q -O apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc && \
    wget -q -O KEYS https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS && \
    echo "${TOMCAT_KEYS_SHA256}  KEYS" | sha256sum -c - && \
    gpg --batch --import KEYS && \
    sha512sum -c apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512 && \
    gpg --batch --verify apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    SIGNER="$(gpg --batch --status-fd=1 --verify apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc apache-tomcat-${TOMCAT_VERSION}.tar.gz 2>/dev/null | awk '/^\[GNUPG:\] VALIDSIG /{ if (NF>=12 && $12 ~ /^[0-9A-F]{40}$/) print $12; else print $3; exit }')" && \
    case "$SIGNER" in \
        *[![:xdigit:]]*) echo "GPG did not report a valid primary-key fingerprint: '$SIGNER'" >&2; exit 1 ;; \
        ????????????????????????????????????????) ;; \
        *) echo "GPG did not report a valid primary-key fingerprint: '$SIGNER'" >&2; exit 1 ;; \
    esac && \
    case "$SIGNER" in \
        5C3C5F3E314C866292F359A8F3AD5C94A67F707E|A9C5DF4D22E99998D9875A5110C01C5A2F6059E7) ;; \
        *) echo "GPG signature not made by an allowed Tomcat release manager: $SIGNER" >&2; exit 1 ;; \
    esac && \
    tar -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    rm -f apache-tomcat-*.tar.gz* KEYS && \
    mv apache-tomcat* ${CATALINA_HOME}

RUN chmod +x ${CATALINA_HOME}/bin/*sh

# Create Tomcat admin user
COPY create_admin_user.sh $CATALINA_HOME/scripts/create_admin_user.sh
COPY tomcat.sh $CATALINA_HOME/scripts/tomcat.sh
RUN chmod +x $CATALINA_HOME/scripts/*.sh

# Create tomcat user
RUN groupadd -r tomcat &&  useradd -g tomcat -u 1000 -d ${CATALINA_HOME} -s /sbin/nologin  -c "Tomcat user" tomcat &&  chown -R tomcat:tomcat ${CATALINA_HOME}

WORKDIR /opt/tomcat

EXPOSE 8080
EXPOSE 8009

USER 1000
CMD ["tomcat.sh"]
