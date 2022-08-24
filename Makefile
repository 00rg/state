CLUSTER       ?= default
REGISTRY      ?= local-registry
REGISTRY_PORT ?= 5555
SERVICE_DIRS  ?= ../hello-service

ARGOCD_VERSION := v2.4.8

# Colors for pretty printing.
color_none := \033[0m
color_bann := \033[38;2;44;220;162m
color_mesg := \033[38;2;20;138;222m

## Function for printing a banner.
banner = \
	echo "\n$(color_bann)=====> $1$(color_none)"

## Function for printing a message.
message = \
	echo "\n$(color_mesg)$1$(color_none)"

## Function for waiting until ENTER is pressed.
wait-confirm = \
	while true; do \
		IFS= read -n 1 -p "Press ENTER to continue..." input; \
		[[ "$${input}" == "" ]] && break || echo; \
	done

## Function for applying KRM resources in a layered approach.
apply-krm-layers = \
	@for layer in $1/*; do \
		id=$$(($${id:-0} + 1)); \
		$(call message,Applying KRM layer $${id}); \
		kustomize build $${layer} | kubectl apply -f - || break; \
		$(call message,Waiting for KRM layer $${id}...); \
		./scripts/wait-ready-all.sh || break; \
	done

.PHONY: test
test:
	@$(call wait-confirm)

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
	@$(call banner,Creating k3d cluster)
	@if [[ $$(k3d cluster list -o=json | jq 'any(.name == "$(CLUSTER)")') == false ]]; then \
		k3d cluster create $(CLUSTER) \
			--port 9080:80@loadbalancer \
			--port 9443:443@loadbalancer \
			--api-port 6443 \
			--k3s-arg="--disable=traefik@server:0" \
			--registry-use k3d-$(REGISTRY):$(REGISTRY_PORT); \
	else \
		echo "Cluster $(CLUSTER) already exists."; \
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

## Updates the Argo CD installation manifests to the specified version.
.PHONY: argocd-update-manifests
argocd-update-manifests:
	@$(call banner,Updating Argo CD manifests)
	@curl -sfo config/applications/platform/argocd/overlays/management/ha-install.yaml \
		https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/ha/install.yaml
	@curl -sfo config/applications/platform/argocd/overlays/local/non-ha-install.yaml \
		https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml
	@echo "Done."

## Updates the Argo CD installation manifests to the specified version.
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

.PHONY: cluster-wait-ready-all
cluster-wait-ready-all:
	@$(call banner,Waiting until all cluster workloads are ready)
	@./scripts/wait-ready-all.sh

.PHONY: init
init:
	@$(call banner,Starting init process)
	@echo "This feature has not yet been implemented."

.PHONY: push-service-images-local
push-service-images-local:
	@$(call banner,Pushing service images to local registry)
	@for dir in $(SERVICE_DIRS); do \
		cd $${dir} && $(MAKE) push-image-local; \
	done

.PHONY: local-without-argocd
local-without-argocd: k3d-create-all push-service-images-local
	@$(call banner,Applying KRM resources directly to cluster)
	@$(call apply-krm-layers,config/clusters/local-without-argocd)

.PHONY: local-with-argocd
local-with-argocd: k3d-create-all push-service-images-local
	@$(call banner,Applying Argo CD KRM resources)
	@$(call apply-krm-layers,config/clusters/local-with-argocd)
	@printf "\nTo view the Argo CD console run: make argocd-port-forward\n"
