SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

TF := ./bin/tf-local.sh

.PHONY: help up status smoke init validate plan apply destroy reset contract

help:
	@printf '%s\n' \
	  'make up                 Start pinned Floci locally.' \
	  'make smoke              Verify local AWS CLI/ECS/SQS behaviour.' \
	  'make init STACK=...     Initialize a named local stack.' \
	  'make validate STACK=... Validate a named local stack.' \
	  'make plan STACK=...     Plan a local stack through the loopback-only wrapper.' \
	  'make apply STACK=...    Apply a Floci-compatible stack (foundation only).' \
	  'make destroy STACK=...  Destroy a local stack through the same wrapper.' \
	  'make contract           Validate the private and edge blueprint interfaces.' \
	  'make reset              Stop Floci and delete only its named Docker volume.'

up:
	docker compose -f ../../tools/floci/compose.yaml up -d

status:
	docker compose -f ../../tools/floci/compose.yaml ps

smoke:
	@bash -c 'source ../../tools/floci/env.sh && ../../tools/floci/smoke.sh'

init:
	@test -n "$(STACK)" || (echo 'STACK is required, e.g. make init STACK=foundation' >&2; exit 64)
	$(TF) $(STACK) init -backend=false

validate:
	@test -n "$(STACK)" || (echo 'STACK is required, e.g. make validate STACK=foundation' >&2; exit 64)
	$(TF) $(STACK) validate

plan:
	@test -n "$(STACK)" || (echo 'STACK is required, e.g. make plan STACK=foundation' >&2; exit 64)
	$(TF) $(STACK) plan -input=false

apply:
	@test -n "$(STACK)" || (echo 'STACK is required, e.g. make apply STACK=foundation' >&2; exit 64)
	$(TF) $(STACK) apply -input=false

destroy:
	@test -n "$(STACK)" || (echo 'STACK is required, e.g. make destroy STACK=foundation' >&2; exit 64)
	$(TF) $(STACK) destroy -input=false

contract:
	@$(MAKE) init STACK=private-application
	@$(MAKE) validate STACK=private-application
	@$(MAKE) init STACK=edge-web
	@$(MAKE) validate STACK=edge-web

reset:
	docker compose -f ../../tools/floci/compose.yaml down -v
