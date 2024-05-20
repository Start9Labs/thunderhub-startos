FROM golang:1.18-alpine3.15 as yqbuild
ENV GO111MODULE=on
RUN apk add git
RUN go install github.com/mikefarah/yq/v4@v4.24.5

# ---------------
# Install Dependencies
# ---------------
FROM node:18.18.2-alpine as deps

WORKDIR /app

# Install dependencies neccesary for node-gyp on node alpine
RUN apk add --update --no-cache \
    libc6-compat \
    python3 \
    make \
    g++

# Install app dependencies
COPY thunderhub/package.json thunderhub/package-lock.json ./
RUN npm ci

# ---------------
# Build App
# ---------------
FROM deps as build

WORKDIR /app

# Set env variables
ARG BASE_PATH=""
ENV BASE_PATH=${BASE_PATH}
ARG NODE_ENV="production"
ENV NODE_ENV=${NODE_ENV}
ENV NEXT_TELEMETRY_DISABLED=1

# Build the NestJS and NextJS application
COPY thunderhub .
RUN npm run build

# Remove non production necessary modules
RUN npm prune --production

# ---------------
# Release App
# ---------------
FROM node:18.18.2-alpine as final

RUN apk add --update --no-cache bash coreutils curl

WORKDIR /app

# Set env variables
ARG BASE_PATH=""
ENV BASE_PATH=${BASE_PATH}
ARG NODE_ENV="production"
ENV NODE_ENV=${NODE_ENV}
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules/ ./node_modules

# Copy NextJS files
COPY --from=build /app/src/client/public ./src/client/public
COPY --from=build /app/src/client/next.config.js ./src/client/
COPY --from=build /app/src/client/.next/ ./src/client/.next

# Copy NestJS files
COPY --from=build /app/dist/ ./dist

EXPOSE 3000

# CMD [ "npm", "run", "start:prod" ]

COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
COPY --from=yqbuild /go/bin/yq /usr/bin/yq
ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
