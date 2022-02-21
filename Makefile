THUNDERHUB_SRC := $(shell find ./thunderhub)
VERSION := $(shell yq e ".version" manifest.yaml)

.DELETE_ON_ERROR:

all: verify

verify: thunderhub.s9pk
	embassy-sdk verify s9pk thunderhub.s9pk

install: thunderhub.s9pk
	embassy-cli package install thunderhub.s9pk

thunderhub.s9pk: manifest.yaml assets/compat/config_spec.yaml assets/compat/config_rules.yaml image.tar instructions.md
	embassy-sdk pack

Dockerfile: $(THUNDERHUB_SRC)
	cp thunderhub/arm64v8.Dockerfile Dockerfile
	patch -u Dockerfile -i thunderhub.patch

image.tar: Dockerfile docker_entrypoint.sh check-web.sh
	docker build --tag start9/thunderhub/main:$(VERSION) .
	docker save -o image.tar start9/thunderhub/main:$(VERSION)

