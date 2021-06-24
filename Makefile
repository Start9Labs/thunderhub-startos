ASSETS := $(shell yq e '.assets.[].src' manifest.yaml)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
THUNDERHUB_SRC := $(shell find ./thunderhub)
DOCKER_CUR_ENGINE := $(shell docker buildx ls | grep "*" | awk '{print $$1;}')


.DELETE_ON_ERROR:

all: thunderhub.s9pk

install: thunderhub.s9pk
	appmgr install thunderhub.s9pk

thunderhub.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar instructions.md
	appmgr -vv pack $(shell pwd) -o thunderhub.s9pk
	appmgr -vv verify thunderhub.s9pk

instructions.md: README.md
	cp README.md instructions.md

Dockerfile: $(THUNDERHUB_SRC)
	cp thunderhub/arm32v7.Dockerfile Dockerfile
	patch -u Dockerfile -i thunderhub.patch

image.tar: Dockerfile docker_entrypoint.sh
	#docker buildx use default
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --no-cache --tag start9/thunderhub --platform=linux/arm/v7 -o type=docker,dest=image.tar .
	#docker buildx use $(DOCKER_CUR_ENGINE)
	#docker save start9/thunderhub > image.tar

