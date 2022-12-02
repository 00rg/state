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
        build_file = "//bazel/third_party/argocd:BUILD.ext.bazel",
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
        build_file = "//bazel/third_party/crossplane:BUILD.ext.bazel",
    )

    http_archive(
        name = "helm",
        urls = ["https://get.helm.sh/helm-v3.10.2-darwin-arm64.tar.gz"],
        sha256 = "460441eea1764ca438e29fa0e38aa0d2607402f753cb656a4ab0da9223eda494",
        strip_prefix = "darwin-arm64",
        build_file = "//bazel/third_party/helm:BUILD.ext.bazel",
    )

    istio_version = "1.16.0"
    http_archive(
        name = "istioctl",
        urls = ["https://github.com/istio/istio/releases/download/{version}/istioctl-{version}-osx-arm64.tar.gz".format(version = istio_version)],
        sha256 = "6089c88b47f24de89ae164afb5d1fc5006d1341b85cb777633a6a599d63414e6",
        build_file = "//bazel/third_party/istioctl:BUILD.ext.bazel",
    )

    k3d_version = "5.4.6"
    http_file(
        name = "k3d",
        urls = ["https://github.com/k3d-io/k3d/releases/download/v{}/k3d-darwin-arm64".format(k3d_version)],
        sha256 = "486baa195157183fb6e32b781dd0a638f662ed5f9c4d80510287ce9630a80081",
        executable = True,
    )

    kubectl_version = "1.25.4"
    http_file(
        name = "kubectl",
        urls = ["https://dl.k8s.io/release/v{}/bin/darwin/arm64/kubectl".format(kubectl_version)],
        sha256 = "61ee3edabfb4db59c102968bd2801d3f0818cff5381e5cb398b0ac5dc72e2ce9",
        executable = True,
    )

    pyyaml_version = "6.0"
    http_archive(
        name = "py_yaml",
        url = "https://files.pythonhosted.org/packages/36/2b/61d51a2c4f25ef062ae3f74576b01638bebad5e045f747ff12643df63844/PyYAML-{}.tar.gz".format(pyyaml_version),
        sha256 = "68fb519c14306fec9720a2a5b45bc9f0c8d1b9c72adf45c37baedfcd949c35a2",
        strip_prefix = "PyYAML-{}/lib/yaml".format(pyyaml_version),
        build_file = "//bazel/third_party/py_yaml:BUILD.ext.bazel",
    )

    rules_python_version = "0.14.0"
    http_archive(
        name = "rules_python",
        sha256 = "a868059c8c6dd6ad45a205cca04084c652cfe1852e6df2d5aca036f6e5438380",
        strip_prefix = "rules_python-{}".format(rules_python_version),
        url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/{}.tar.gz".format(rules_python_version),
    )

    vector_chart_version = "0.17.0"
    http_archive(
        name = "vector",
        urls = ["https://github.com/vectordotdev/helm-charts/releases/download/vector-{version}/vector-{version}.tgz".format(
            version = vector_chart_version,
        )],
        sha256 = "4c12b5d95b03983c42208de2fa2b28f05089c40f518bce0b050a4a3480bafd9a",
        strip_prefix = "vector",
        build_file = "//bazel/third_party/vector:BUILD.ext.bazel",
    )
