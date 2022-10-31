include .support/make/build-dirs.mk
include .support/make/third-party.mk
include .support/make/crossplane.mk

REGISTRY          ?= local-registry
REGISTRY_PORT     ?= 5555
SERVICE_DIRS      ?= ../hello-service
PUSH_LOCAL_IMAGES ?= false

# List of clusters that can be run locally.
local_clusters := $(shell find config/clusters \
	-maxdepth 1 -mindepth 1 \
	\( -name 'init' -o -name '????-???-loc-xxxxx-????' \) \
	-printf "%f\n")

# Colors for pretty printing.
color_none    := \033[0m
color_banner  := \033[38;2;44;220;162m
color_message := \033[38;2;20;138;222m

## Function for printing a banner.
banner = \
	echo "\n$(color_banner)=====> $1$(color_none)"

## Function for printing a message.
message = \
	echo "\n$(color_message)$1$(color_none)"

## Check that the CLUSTER variable has been set appropriately.
check-cluster = \
	if [[ -z "$(findstring $(CLUSTER),$(local_clusters),)" ]]; then \
		printf "CLUSTER must be set to one of the following local clusters:\n"; \
		printf "%s\n" $(local_clusters); \
		printf "\n"; \
		exit 1; \
	fi

## Function for waiting until ENTER is pressed.
wait-confirm = \
	while true; do \
		IFS= read -n 1 -p "Press ENTER to continue..." input; \
		[[ "$${input}" == "" ]] && break || echo; \
	done

## Creates a local container registry.
.PHONY: k3d-create-registry
k3d-create-registry:
	@$(call banner,Creating k3d container registry)
	@if [[ $$(k3d registry list -o=json | jq 'any(.name == "k3d-$(REGISTRY)")') == false ]]; then \
		k3d registry create $(REGISTRY) --port $(REGISTRY_PORT) > /dev/null; \
		echo "Created local registry $(REGISTRY)."; \
	else \
		echo "Registry $(REGISTRY) already exists."; \
	fi

## Creates a local k3d cluster.
.PHONY: k3d-create-cluster
k3d-create-cluster:
	@$(call check-cluster)
	@$(call banner,Creating k3d cluster)
	@if [[ $$(k3d cluster list -o=json | jq 'any(.name == "$(CLUSTER)")') == false ]]; then \
		k3d cluster create $(CLUSTER) \
			--port 8080:31000@server:0 \
			--port 9080:31001@server:0 \
			--api-port 6443 \
			--k3s-arg="--disable=traefik@server:0" \
			--registry-use k3d-$(REGISTRY):$(REGISTRY_PORT); \
	else \
		echo "Cluster $(CLUSTER) already exists."; \
	fi
	@if [[ $$(kubectl config current-context) != k3d-$(CLUSTER) ]]; then \
		kubectl config use-context k3d-$(CLUSTER); \
	fi

## Creates the local k3d registry and cluster.
.PHONY: k3d-create-all
k3d-create-all: k3d-create-registry k3d-create-cluster

## Deletes the local container registry.
.PHONY: k3d-delete-registry
k3d-delete-registry:
	@$(call banner,Deleting k3d container registry)
	@if [[ $$(k3d registry list -o=json | jq 'any(.name == "k3d-$(REGISTRY)")') == true ]]; then \
		k3d registry delete $(REGISTRY); \
		echo "Deleted registry $(REGISTRY)."; \
	else \
		echo "Registry $(REGISTRY) does not exist."; \
	fi

## Deletes the local k3d cluster.
.PHONY: k3d-delete-cluster
k3d-delete-cluster:
	@$(call check-cluster)
	@$(call banner,Deleting k3d cluster)
	@if [[ $$(k3d cluster list -o=json | jq 'any(.name == "$(CLUSTER)")') == true ]]; then \
		k3d cluster delete $(CLUSTER); \
		echo "Deleted cluster $(CLUSTER)."; \
	else \
		echo "Cluster $(CLUSTER) does not exist."; \
	fi

## Deletes the local k3d cluster and registry.
.PHONY: k3d-delete-all
k3d-delete-all: k3d-delete-cluster k3d-delete-registry

.PHONY: argocd-port-forward
argocd-port-forward:
	@$(call banner,Port forwarding Argo CD)
	@kubectl -n argocd get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d | pbcopy
	@printf "You can login to Argo CD at http://localhost:8080\n"
	@printf "The username is 'admin' and the password has been copied to the clipboard\n\n"
	@kubectl port-forward svc/argocd-server -n argocd 8080:443

.PHONY: shellcheck
shellcheck:
	@$(call banner,Checking shell scripts with ShellCheck)
	@shellcheck $(shell find . -name '*.sh')

.PHONY: shfmt
shfmt:
	@$(call banner,Checking shell scripts with shfmt)
	@shfmt -i 2 -ci -sr -bn -d $(shell find . -name '*.sh')

.PHONY: lint
lint: shellcheck shfmt

.PHONY: boot-cluster
boot-cluster: k3d-create-all push-service-images-local
	@$(call banner,Booting cluster $(CLUSTER))
ifeq ($(CLUSTER),init)
	@$(call crossplane-init)
endif
	@.support/scripts/wave-apply.sh config/clusters/$(CLUSTER)

.PHONY: push-service-images-local
push-service-images-local:
ifeq ($(PUSH_LOCAL_IMAGES),true)
	@$(call banner,Pushing service images to local registry)
	@for dir in $(SERVICE_DIRS); do \
		cd $${dir} && $(MAKE) push-image-local; \
	done
endif
