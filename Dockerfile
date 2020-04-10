FROM python:alpine
RUN apk -uv add --no-cache \
        openssl-client \
        jq \
        less \
        && pip install --upgrade awscli python-magic

ADD pull.sh /
RUN mkdir /root/.ssh/ && chmod 600 /root/.ssh/

ENTRYPOINT ["/bin/sh"]
