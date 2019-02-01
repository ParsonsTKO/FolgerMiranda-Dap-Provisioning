# Defaults
ifdef resource
options := -target=$(resource)
endif
service := client

# Commands
plan = terraform plan $(options)
apply = terraform apply $(options)
install = terraform init && terraform get
destroy = terraform destroy
init = terraform init

# Load custom setitngs
-include .env
export
PROVISION ?= docker
include etc/$(PROVISION)/makefile

crypt:
	git-crypt init

deploy: ## Deploy a ECS service
	make apply resource=module.dap_$(service)_service.aws_ecs_service.this

push: branch := $(shell git rev-parse --abbrev-ref HEAD)
push: ## Review, add, commit and push changes using commitizen. Usage: make push
	git diff
	git add -A .
	@docker run --rm -it -v $(CURDIR):/app -v $(HOME)/.gitconfig:/root/.gitconfig aplyca/commitizen
	git pull origin $(branch)
	git push -u origin $(branch)

h help: ## This help.
	@echo 'Usage: make <task>' 
	@echo 'Default task: plan'
	@echo
	@echo 'Tasks:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9., _-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := plan
.PHONY: all