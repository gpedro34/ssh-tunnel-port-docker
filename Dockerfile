FROM alpine:3.9

RUN apk add --update openssh-client && rm -rf /var/cache/apk/* \
    && mkdir /root/.ssh && mkdir /root/.ssh/.keys

COPY ./ssh/config /root/.ssh/config
COPY ./ssh/known_hosts /root/.ssh/known_hosts
COPY ./ssh/keys/* /root/.ssh/.keys/

RUN chmod -R 700 /root/.ssh/.keys

CMD ssh -L 0.0.0.0:$LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT $SSH_HOST

EXPOSE 1-65535