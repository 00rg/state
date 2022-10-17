argocd_version       := 2.4.12
crossplane_version   := 1.9.1
istio_version        := 1.15.0
vector_chart_version := 0.16.0
vector_image_version := 0.24.1-distroless-libc

##
## Updates the third party Helm repos.
##
.PHONY: third-party-helm-repos
third-party-helm-repos:
	@helm repo add crossplane-stable https://charts.crossplane.io/stable > /dev/null
	@helm repo add vector https://helm.vector.dev > /dev/null
	@helm repo update > /dev/null

##
## Updates the Crossplane manifests.
##
.PHONY: third-party-update-crossplane
third-party-update-crossplane: third-party-helm-repos
	@$(call banner,Updating Crossplane to version $(crossplane_version))
	@helm template crossplane crossplane-stable/crossplane \
		--version $(crossplane_version) \
		--namespace crossplane-system \
		> config/applications/platform/crossplane/base/crossplane.gen.yaml

##
## Clones the Argo CD repository.
##
$(third_party_dir)/argocd-$(argocd_version): $(third_party_dir)
	@git clone --quiet --depth=1 --single-branch --branch=v$(argocd_version) \
		git@github.com:argoproj/argo-cd.git $@

##
## Updates the Argo CD manifests.
##
.PHONY: third-party-update-argocd
third-party-update-argocd: $(third_party_dir)/argocd-$(argocd_version)
	@$(call banner,Updating Argo CD to version $(argocd_version))
	@kustomize build $(third_party_dir)/argocd-$(argocd_version)/manifests/cluster-install \
		> config/applications/platform/argocd/overlays/local/argocd.gen.yaml
	@kustomize build $(third_party_dir)/argocd-$(argocd_version)/manifests/crds \
		> config/applications/platform/argocd/overlays/management/argocd.gen.yaml
	@echo '---' >> config/applications/platform/argocd/overlays/management/argocd.gen.yaml
	@kustomize build $(third_party_dir)/argocd-$(argocd_version)/manifests/ha/namespace-install \
		>> config/applications/platform/argocd/overlays/management/argocd.gen.yaml

##
## Installs istioctl.
##
$(third_party_dir)/istio-$(istio_version)/istioctl: $(third_party_dir)
	@mkdir $(third_party_dir)/istio-$(istio_version)
	@curl -Lsf https://github.com/istio/istio/releases/download/$(istio_version)/istioctl-$(istio_version)-osx-arm64.tar.gz -o istio.tar.gz \
		| tar -xz -C $@

##
## Updates the Istio Operator manifests.
##
.PHONY: third-party-update-istio-operator
third-party-update-istio-operator: $(third_party_dir)/istio-$(istio_version)/istioctl
	@$(call banner,Updating Istio Operator to version $(istio_version))
	$(third_party_dir)/istio-$(istio_version)/istioctl operator dump \
		> config/applications/platform/istio-operator/base/istio-operator.gen.yaml

##
## Update Vector manifests.
##
.PHONY: third-party-update-vector
third-party-update-vector: third-party-helm-repos
	@$(call banner,Updating Vector to version $(vector_chart_version))
	@helm template vector-agent vector/vector \
		--version $(vector_chart_version) \
		--namespace vector \
		--set fullnameOverride=vector-agent \
		--set role=Agent \
		--set image.tag=$(vector_image_version) \
		--set service.enabled=true \
		> config/applications/platform/vector/components/vector-agent/vector-agent.gen.yaml
	@helm template vector-aggregator vector/vector \
		--version $(vector_chart_version) \
		--namespace vector \
		--set fullnameOverride=vector-aggregator \
		--set role=Aggregator \
		--set image.tag=$(vector_image_version) \
		--set service.enabled=false \
		> config/applications/platform/vector/components/vector-aggregator/vector-aggregator.gen.yaml
