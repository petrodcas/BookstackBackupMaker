ARG TAG=latest
FROM alpine:${TAG}
RUN apk update && apk add gpg gpg-agent git openssh-client mysql-client tar openssl msmtp
RUN echo -e "Host github.com\n  StrictHostKeyChecking no\n" >> /etc/ssh/ssh_config
WORKDIR /root
ADD --chmod=600 ./scripts/msmtprc ./.msmtprc
ADD --chmod=500 ./scripts/init.sh ./init.sh
ADD --chmod=500 ./scripts/validators.sh ./validators.sh
ADD --chmod=500 ./scripts/.envvars ./.envvars
CMD ./init.sh