"""Provides dependency loading functions."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def org_util_dependencies():
    """Declare base dependencies."""

    bazel_skylib_version = "1.3.0"
    maybe(
        http_archive,
        name = "bazel_skylib",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/{v}/bazel-skylib-{v}.tar.gz".format(v = bazel_skylib_version)],
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
    )

    multirun_version = "0.2.0"
    maybe(
        http_archive,
        name = "rules_multirun",
        urls = ["https://github.com/keith/rules_multirun/archive/refs/tags/{}.tar.gz".format(multirun_version)],
        sha256 = "fdaed317c259c5eee82e48261437466238aff3f997e890366ca9356238344899",
        strip_prefix = "rules_multirun-{}".format(multirun_version),
    )

def org_binary_dependencies():
    """Declare binary tool dependencies."""

    helm_version = "3.10.3"
    maybe(
        http_archive,
        name = "helm",
        urls = ["https://get.helm.sh/helm-v{}-darwin-arm64.tar.gz".format(helm_version)],
        sha256 = "4f3490654349d6fee8d4055862efdaaf9422eca1ffd2a15393394fd948ae3377",
        strip_prefix = "darwin-arm64",
        build_file = "//bazel/third_party:BUILD.helm.bazel",
    )

    istio_version = "1.16.1"
    maybe(
        http_archive,
        name = "istioctl",
        urls = ["https://github.com/istio/istio/releases/download/{v}/istioctl-{v}-osx-arm64.tar.gz".format(v = istio_version)],
        sha256 = "119cccb9398bb78ad34f3db1dbda778b3e88ac0dbbd089f1f6353d2caf07955b",
        build_file = "//bazel/third_party:BUILD.istioctl.bazel",
    )

    k3d_version = "5.4.6"
    http_file(
        name = "k3d",
        urls = ["https://github.com/k3d-io/k3d/releases/download/v{}/k3d-darwin-arm64".format(k3d_version)],
        sha256 = "486baa195157183fb6e32b781dd0a638f662ed5f9c4d80510287ce9630a80081",
        executable = True,
    )

    kubectl_version = "1.26.0"
    http_file(
        name = "kubectl",
        urls = ["https://dl.k8s.io/release/v{}/bin/darwin/arm64/kubectl".format(kubectl_version)],
        sha256 = "cc7542dfe67df1982ea457cc6e15c171e7ff604a93b41796a4f3fa66bd151f76",
        executable = True,
    )

def org_manifest_dependencies():
    """Declare Kubernetes manifest dependencies."""

    argocd_version = "2.5.5"
    maybe(
        http_archive,
        name = "argocd",
        urls = ["https://github.com/argoproj/argo-cd/archive/refs/tags/v{}.tar.gz".format(argocd_version)],
        sha256 = "f8611c4934079662b0465f17c070838d7ac51fd953b8812099d50b62051770d8",
        strip_prefix = "argo-cd-{}/manifests".format(argocd_version),
        build_file = "//bazel/third_party:BUILD.argocd.bazel",
    )

    crossplane_version = "1.10.1"
    maybe(
        http_archive,
        name = "crossplane",
        urls = ["https://charts.crossplane.io/stable/crossplane-{}.tgz".format(crossplane_version)],
        sha256 = "0b93a206fd298f9c6c015eaf0cbf66f4235be5e9084abe4aa3d66f57f2c0e40d",
        strip_prefix = "crossplane",
        build_file = "//bazel/third_party:BUILD.crossplane.bazel",
    )

    kube_prometheus_chart_version = "43.1.2"
    maybe(
        http_archive,
        name = "kube_prometheus",
        urls = ["https://github.com/prometheus-community/helm-charts/releases/download/kube-prometheus-stack-{v}/kube-prometheus-stack-{v}.tgz".format(v = kube_prometheus_chart_version)],
        sha256 = "59e49de5da26c095276ce344ffab0038fed91f198da9ca14c78f8f4fb40c5c9b",
        strip_prefix = "kube-prometheus-stack",
        build_file = "//bazel/third_party:BUILD.kube_prometheus.bazel",
        patch_args = ["-p1"],
        patches = [
            "//bazel/third_party/kube_prometheus:Chart.yaml.patch",
            "//bazel/third_party/kube_prometheus:Chart.lock.patch",
        ],
    )

    grafana_agent_operator_chart_version = "0.2.8"
    maybe(
        http_archive,
        name = "grafana_agent_operator",
        urls = ["https://github.com/grafana/helm-charts/releases/download/grafana-agent-operator-{v}/grafana-agent-operator-{v}.tgz".format(v = grafana_agent_operator_chart_version)],
        sha256 = "9022509c0e9075c9f103a11f5ee3109d0250a3f756d09497f94b15c47fd7ff42",
        strip_prefix = "grafana-agent-operator",
        build_file = "//bazel/third_party:BUILD.grafana_agent_operator.bazel",
    )

    loki_chart_version = "3.8.0"
    maybe(
        http_archive,
        name = "loki",
        urls = ["https://github.com/grafana/helm-charts/releases/download/helm-loki-{v}/loki-{v}.tgz".format(v = loki_chart_version)],
        sha256 = "81fcfe9bfc7334f5feeefb0b2ff7ba489135d82da3f77a0076d650ef2c5aba6f",
        strip_prefix = "loki",
        build_file = "//bazel/third_party:BUILD.loki.bazel",
    )

def org_python_dependencies():
    """Declare Python dependencies."""

    rules_python_version = "0.14.0"
    maybe(
        http_archive,
        name = "rules_python",
        urls = ["https://github.com/bazelbuild/rules_python/archive/refs/tags/{}.tar.gz".format(rules_python_version)],
        sha256 = "a868059c8c6dd6ad45a205cca04084c652cfe1852e6df2d5aca036f6e5438380",
        strip_prefix = "rules_python-{}".format(rules_python_version),
    )

def org_go_dependencies():
    """Declare Go dependencies."""

    # Golang stuff which is required for building Golang code but is also required
    # by rules_docker as a workaround for https://github.com/bazelbuild/rules_docker/issues/2036
    # and https://github.com/bazelbuild/bazel/issues/10134#issuecomment-1193395705.
    # TODO: Move below out into a go_deps.bzl file and go_dependencies() function.
    # Probably want: k8s_deps.bzl/k8s_dependencies(), container_deps.bzl/container_dependencies(), etc.

    rules_go_version = "0.36.0"
    maybe(
        http_archive,
        # All dependencies are named after their official workspace name. In the case of
        # io_bazel_rules_go, this is strictly required since bazel_gazelle expects to be
        # able to resolve @io_bazel_rules_go references.
        name = "io_bazel_rules_go",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v{v}/rules_go-v{v}.zip".format(v = rules_go_version)],
        sha256 = "ae013bf35bd23234d1dea46b079f1e05ba74ac0321423830119d3e787ec73483",
    )

    bazel_gazelle_version = "0.27.0"
    maybe(
        http_archive,
        name = "bazel_gazelle",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v{v}/bazel-gazelle-v{v}.tar.gz".format(v = bazel_gazelle_version)],
        sha256 = "efbbba6ac1a4fd342d5122cbdfdb82aeb2cf2862e35022c752eaddffada7c3f3",
    )

def org_rust_dependencies():
    """Declare Rust dependencies."""

    # Note: I have tried unsuccesfully to get Cargo Raze working through Bazel as described in
    # https://github.com/google/cargo-raze#using-cargo-raze-through-bazel. Different version
    # combinations of Raze and rules_rust produce different errors but it doesn't seem ready
    # to run on Apple M1 yet.

    rules_rust_version = "0.14.0"
    maybe(
        http_archive,
        name = "rules_rust",
        urls = ["https://github.com/bazelbuild/rules_rust/releases/download/{v}/rules_rust-v{v}.tar.gz".format(v = rules_rust_version)],
        sha256 = "dd79bd4e2e2adabae738c5e93c36d351cf18071ff2acf6590190acf4138984f6",
    )

def org_container_dependencies():
    """Declare container dependencies."""

    rules_docker_version = "0.25.0"
    maybe(
        http_archive,
        name = "io_bazel_rules_docker",
        urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v{v}/rules_docker-v{v}.tar.gz".format(v = rules_docker_version)],
        sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
    )
