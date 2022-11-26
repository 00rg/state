load("//bazel:rules.bzl", "generate_manifests", "helm_template", "istio_operator", "k3d_targets", "kustomize_build")

_GENERATED_MANIFESTS = {
    "//:argocd_ha_manifest": "config/platform/argocd/overlays/management/argocd.gen.yaml",
    "//:argocd_non_ha_manifest": "config/platform/argocd/overlays/local/argocd.gen.yaml",
    "//:crossplane_manifest": "config/platform/crossplane-base/base/crossplane.gen.yaml",
    "//:istio_operator_manifest": "config/platform/istio-operator/base/istio-operator.gen.yaml",
    "//:vector_agent_manifest": "config/platform/vector/components/vector-agent/vector-agent.gen.yaml",
    "//:vector_aggregator_manifest": "config/platform/vector/components/vector-aggregator/vector-aggregator.gen.yaml",
}

istio_operator(
    name = "istio_operator_manifest",
)

kustomize_build(
    name = "argocd_non_ha_manifest",
    dirs = ["cluster-install"],
    tarball = "@argocd//:tarball",
)

kustomize_build(
    name = "argocd_ha_manifest",
    dirs = [
        "crds",
        "ha/namespace-install",
    ],
    tarball = "@argocd//:tarball",
)

helm_template(
    name = "crossplane_manifest",
    namespace = "crossplane-system",
    release_name = "crossplane",
    tarball = "@crossplane//:tarball",
    values_file = "//bazel:crossplane.values.yaml",
)

helm_template(
    name = "vector_agent_manifest",
    namespace = "vector",
    release_name = "vector-agent",
    tarball = "@vector//:tarball",
    values_file = "//bazel:vector-agent.values.yaml",
)

helm_template(
    name = "vector_aggregator_manifest",
    namespace = "vector",
    release_name = "vector-aggregator",
    tarball = "@vector//:tarball",
    values_file = "//bazel:vector-aggregator.values.yaml",
)

generate_manifests(
    name = "generate_manifests",
    manifests = _GENERATED_MANIFESTS,
)

k3d_targets(name = "k3d")
