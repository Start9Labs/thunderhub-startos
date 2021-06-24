# ---------------
# Install Dependencies
# ---------------
FROM node:10-alpine as deps

WORKDIR /app

# Install dependencies neccesary for node-gyp on node alpine
RUN apk add --update --no-cache \
    libc6-compat \
    python3 \
    make \
    g++


# Install app dependencies
COPY ./thunderhub/package.json ./thunderhub/package-lock.json ./
RUN npm install

FROM golang:1.14.15-alpine3.11 as yqbuild

ENV GO111MODULE=on
RUN go get github.com/mikefarah/yq/v4

# ---------------
# Build App
# ---------------
FROM deps as build

WORKDIR /app

# Set env variables
ARG BASE_PATH=""
ENV BASE_PATH=${BASE_PATH}
ENV NEXT_TELEMETRY_DISABLED=1

# Build the NextJS application
COPY ./thunderhub .
RUN npm run build

# Remove non production necessary modules
RUN npm prune --production

# ---------------
# Release App
# ---------------
FROM node:10-alpine

RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories
RUN apk add --update --no-cache yq bash

WORKDIR /app

# Set env variables
ARG BASE_PATH=""
ENV BASE_PATH=${BASE_PATH}
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=build /app/package.json /app/package-lock.json /app/next.config.js ./
COPY --from=build /app/public ./public
COPY --from=build /app/node_modules/ ./node_modules 
COPY --from=build /app/.next/ ./.next
COPY --from=yqbuild /go/bin/yq /usr/bin/yq

COPY ./thunderhub/scripts/initCookie.sh ./scripts/initCookie.sh

EXPOSE 3000 

COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]