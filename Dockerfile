FROM debian:trixie
LABEL org.opencontainers.image.authors="jean.pommier@pi-geosolutions.fr"
LABEL version="1.1.0"
LABEL description="Gives a SSH access + restic and a few useful tools"

# install ssh server + system utilities
RUN apt-get update && \
    apt-get install -y \
                acl \
                bzip2 \
                cron \
                curl \
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
                wget \
    && rm -rf /var/lib/apt/lists/*

# RUN mkdir /var/run/sshd && \
#     chmod 0755 /var/run/sshd

EXPOSE 22

ENV NAME=backup-toolbox

COPY root /
RUN chmod +x /root/scripts/* &&\
    chmod +x /entrypoint.sh &&\
    chmod +x /docker-entrypoint.d/*

# ENV SSH_KEY_FILE=""
# ENV SSH_KEY=""
# ENV RESTIC_REPOSITORY=""
# ENV RESTIC_PASSWORD_FILE=""
# ENV RESTIC_OPTION_FILE=""
# ENV RESTIC_OPTION=""
# ENV SSH_PASSWD_FILE=""

ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["/usr/sbin/sshd", "-D"]
