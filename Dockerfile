FROM apotdevin/thunderhub:v0.13.31

RUN apk add --update --no-cache yq; \
    rm -f /var/cache/apk/*

COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
