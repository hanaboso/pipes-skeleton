##### MUTAGEN_SYNC #####
USE_LO=true
MTGN_CONTAINER=pipes-skeleton_php-sdk_1
MTGN_PATH=$(shell pwd)/php-sdk
include ./Makefile-mutagen
##### ____________ #####

DC=docker-compose
PHP_SDK=docker-compose exec -T php-sdk
NODE_SDK=docker-compose exec -T node-sdk

ALIAS?=alias
Darwin:
	sudo ifconfig lo0 $(ALIAS) $(shell awk '$$1 ~ /^DEV_IP/' .env.dist | sed -e "s/^DEV_IP=//")
Linux:
	@echo 'skipping ...'
.lo0-up:
	-@make `uname`
.lo0-down:
	-@make `uname` ALIAS='-alias'
.env:
	sed -e "s/{DEV_UID}/$(shell if [ "$(shell uname)" = "Linux" ]; then echo $(shell id -u); else echo '1001'; fi)/g" \
		-e "s/{DEV_GID}/$(shell if [ "$(shell uname)" = "Linux" ]; then echo $(shell id -g); else echo '1001'; fi)/g" \
		-e "s/{SSH_AUTH}/$(shell if [ "$(shell uname)" = "Linux" ]; then echo '${SSH_AUTH_SOCK}' | sed 's/\//\\\//g'; else echo '\/run\/host-services\/ssh-auth.sock'; fi)/g" \
		-e "s|{DOCKER_SOCKET_PATH}|$(shell test -S /var/run/docker-$${USER}.sock && echo /var/run/docker-$${USER}.sock || echo /var/run/docker.sock)|g" \
		-e "s|{PROJECT_SOURCE_PATH}|$(shell pwd)|g" \
		.env.dist > .env; \

init-dev: docker-up-force composer-install clear-cache yarn-install start

# Docker section
docker-up-force: .env .lo0-up
	$(DC) pull --ignore-pull-failures
	$(DC) up -d --force-recreate --remove-orphans

docker-down-clean: .env .lo0-down
	$(DC) down -v

# Composer section
composer-install:
	$(PHP_SDK) composer install

# Yarn section
start:
	$(NODE_SDK) yarn start

yarn-install:
	$(NODE_SDK) yarn install

# App section
clear-cache:
	$(PHP_SDK) rm -rf var/log
	$(PHP_SDK) php bin/console cache:clear --env=dev
	$(PHP_SDK) php bin/console cache:warmup --env=dev
