load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//bazel:rules.bzl", "helm_template", "istio_operator", "kustomize_build")

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

write_file(
    name = "generate_manifests_wrapper",
    out = "generate_manifests.sh",
    content = [
        "#!/usr/bin/env bash",
    ] + [
        "cp -f {src}.yaml $BUILD_WORKSPACE_DIRECTORY/{dest}".format(
            src = k.lstrip("//:"),
            dest = v,
        )
        for [
            k,
            v,
        ] in _GENERATED_MANIFESTS.items()
    ],
)

sh_binary(
    name = "generate_manifests",
    srcs = ["generate_manifests.sh"],
    data = _GENERATED_MANIFESTS.keys(),
)
