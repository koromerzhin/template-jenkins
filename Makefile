isDocker := $(shell docker info > /dev/null 2>&1 && echo 1)

.DEFAULT_GOAL := help
STACK         := jenkins
NETWORK       := proxynetwork

WWW         := $(STACK)_www
WWWFULLNAME := $(WWW).1.$$(docker service ps -f 'name=$(WWW)' $(WWW) -q --no-trunc | head -n1)


SUPPORTED_COMMANDS := sleep contributors docker logs git linter ssh inspect update
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

package-lock.json: package.json
	@npm install

node_modules: package-lock.json
	@npm install

isdocker: ## Docker is launch
ifeq ($(isDocker), 0)
	@echo "Docker is not launch"
	exit 1
endif

contributors: node_modules ## Contributors
ifeq ($(COMMAND_ARGS),add)
	@npm run contributors add
else ifeq ($(COMMAND_ARGS),check)
	@npm run contributors check
else ifeq ($(COMMAND_ARGS),generate)
	@npm run contributors generate
else
	@npm run contributors
endif

docker: isdocker ## Scripts docker
ifeq ($(COMMAND_ARGS),create-network)
	@docker network create --driver=overlay $(NETWORK)
else ifeq ($(COMMAND_ARGS),deploy)
	@docker stack deploy -c docker-compose.yml $(STACK)
else ifeq ($(COMMAND_ARGS),image-pull)
	@docker image pull jenkins/jenkins:lts
else ifeq ($(COMMAND_ARGS),ls)
	@docker stack services $(STACK)
else ifeq ($(COMMAND_ARGS),stop)
	@docker stack rm $(STACK)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make docker ARGUMENT"
	@echo "---"
	@echo "create-network: create network"
	@echo "deploy: deploy"
	@echo "image-pull: Get docker image"
	@echo "ls: docker service"
	@echo "stop: docker stop"
endif

logs: isdocker ## Scripts logs
ifeq ($(COMMAND_ARGS),stack)
	@docker service logs -f --tail 100 --raw $(STACK)
else ifeq ($(COMMAND_ARGS),www)
	@docker service logs -f --tail 100 --raw $(WWWFULLNAME)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make logs ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "www: WWW"
endif

git: node_modules ## Scripts GIT
ifeq ($(COMMAND_ARGS),commit)
	@npm run commit
else ifeq ($(COMMAND_ARGS),status)
	@git status
else ifeq ($(COMMAND_ARGS),check)
	@make bdd validate -i
	@make contributors check -i
	@make linter all -i
	@make git status -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make git ARGUMENT"
	@echo "---"
	@echo "commit: Commit data"
	@echo "check: CHECK before"
	@echo "status: status"
endif

install: node_modules ## Installation
	@make docker deploy -i

sleep: ## sleep
	@sleep  $(COMMAND_ARGS)

linter: node_modules  ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter eslint -i
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else ifeq ($(COMMAND_ARGS),eslint)
	@npm run eslint
else ifeq ($(COMMAND_ARGS),eslint-fix)
	@npm run eslint-fix
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
	@echo "readme: linter README.md"
	@echo "eslint: indique les erreurs sur le code JavaScript à partir d'un standard"
	@echo "eslint-fix: fixe le code JavaScript à partir d'un standard"
endif

ssh: isdocker ## SSH
ifeq ($(COMMAND_ARGS),www)
	@docker exec -it $(WWWFULLNAME) /bin/bash
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make ssh ARGUMENT"
	@echo "---"
	@echo "www: WWW"
endif

inspect: isdocker ## inspect
ifeq ($(COMMAND_ARGS),www)
	@docker service inspect $(WWW)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make inspect ARGUMENT"
	@echo "---"
	@echo "www: WWW"
endif

update: isdocker ## ssh
ifeq ($(COMMAND_ARGS),www)
	@docker service update $(WWW)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make update ARGUMENT"
	@echo "---"
	@echo "www: WWW"
endif