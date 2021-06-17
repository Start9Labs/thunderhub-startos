ASSETS := $(shell yq e '.assets.[].src' manifest.yaml)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
HELLO_WORLD_SRC := $(shell find ./thunderhub)

.DELETE_ON_ERROR:

all: thunderhub.s9pk

install: thunderhub.s9pk
	appmgr install thunderhub.s9pk

thunderhub.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar instructions.md
	appmgr -vv pack $(shell pwd) -o thunderhub.s9pk
	appmgr -vv verify thunderhub.s9pk

instructions.md: README.md
	cp README.md instructions.md

Dockerfile:
	cp thunderhub/arm32v7.Dockerfile Dockerfile
	patch -u Dockerfile -i thunderhub.patch

image.tar: Dockerfile docker_entrypoint.sh
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/thunderhub --platform=linux/arm/v7 -o type=docker,dest=image.tar .
