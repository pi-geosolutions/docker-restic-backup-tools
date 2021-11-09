FROM debian:bullseye
MAINTAINER Jean Pommier "jp@pi-geosolutions.fr"
# Gives a SSH access + restic and a few useful tools

ENV SSH_KEY_FILE ""
ENV SSH_KEY ""
ENV RESTIC_REPOSITORY ""
ENV RESTIC_PASSWORD_FILE ""
ENV RESTIC_OPTION_FILE ""
ENV RESTIC_OPTION ""
ENV SSH_PASSWD_FILE ""


# install ssh server + system utilities
RUN apt-get update && \
    apt-get install -y \
                acl \
                bzip2 \
                git \
                ldap-utils \
                mariadb-client \
                openssh-server \
                postgresql-client \
                nano \
                restic \
                rsync \
                sshpass \
                vim \
                wget

RUN mkdir /var/run/sshd && \
    chmod 0755 /var/run/sshd

EXPOSE 22

ENV NAME=restore-console

COPY root /
RUN chmod +x /root/scripts/* &&\
    chmod +x /entrypoint.sh &&\
    chmod +x /docker-entrypoint.d/*

ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["/usr/sbin/sshd", "-D"]
