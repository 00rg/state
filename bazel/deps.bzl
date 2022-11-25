"""Provides dependency loading functions."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def local_dependencies():
    """Declares external dependencies for this repository."""

    argocd_version = "2.5.2"
    http_archive(
        name = "argocd",
        urls = ["https://github.com/argoproj/argo-cd/archive/refs/tags/v{}.tar.gz".format(argocd_version)],
        sha256 = "a210784ae3ee017d1bd83772b04ee125e4bdccf0eb6fc15aa796d009b56440ec",
        strip_prefix = "argo-cd-{}/manifests".format(argocd_version),
        build_file = "//bazel:tarball.BUILD",
    )

    http_archive(
        name = "bazel_skylib",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz"],
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
    )

    crossplane_version = "1.10.1"
    http_archive(
        name = "crossplane",
        urls = ["https://charts.crossplane.io/stable/crossplane-{}.tgz".format(crossplane_version)],
        sha256 = "0b93a206fd298f9c6c015eaf0cbf66f4235be5e9084abe4aa3d66f57f2c0e40d",
        strip_prefix = "crossplane",
        build_file = "//bazel:tarball.BUILD",
    )

    http_archive(
        name = "helm",
        urls = ["https://get.helm.sh/helm-v3.10.2-darwin-arm64.tar.gz"],
        sha256 = "460441eea1764ca438e29fa0e38aa0d2607402f753cb656a4ab0da9223eda494",
        strip_prefix = "darwin-arm64",
        build_file = "//bazel:helm.BUILD",
    )

    istio_version = "1.16.0"
    http_archive(
        name = "istioctl",
        urls = ["https://github.com/istio/istio/releases/download/{version}/istioctl-{version}-osx-arm64.tar.gz".format(version = istio_version)],
        sha256 = "6089c88b47f24de89ae164afb5d1fc5006d1341b85cb777633a6a599d63414e6",
        build_file = "//bazel:istioctl.BUILD",
    )

    k3d_version = "5.4.6"
    http_file(
        name = "k3d",
        urls = ["https://github.com/k3d-io/k3d/releases/download/v{}/k3d-darwin-arm64".format(k3d_version)],
        sha256 = "486baa195157183fb6e32b781dd0a638f662ed5f9c4d80510287ce9630a80081",
        executable = True,
    )

    http_archive(
        name = "kustomize",
        urls = ["https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.7/kustomize_v4.5.7_darwin_arm64.tar.gz"],
        sha256 = "3c1e8b95cef4ff6e52d5f4b8c65b8d9d06b75f42d1cb40986c1d67729d82411a",
        build_file = "//bazel:kustomize.BUILD",
    )

    vector_chart_version = "0.17.0"
    http_archive(
        name = "vector",
        urls = ["https://github.com/vectordotdev/helm-charts/releases/download/vector-{version}/vector-{version}.tgz".format(
            version = vector_chart_version,
        )],
        sha256 = "4c12b5d95b03983c42208de2fa2b28f05089c40f518bce0b050a4a3480bafd9a",
        strip_prefix = "vector",
        build_file = "//bazel:tarball.BUILD",
    )
