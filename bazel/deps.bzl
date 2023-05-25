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

    multirun_version = "0.4.1"
    maybe(
        http_archive,
        name = "rules_multirun",
        urls = ["https://github.com/keith/rules_multirun/archive/refs/tags/{}.tar.gz".format(multirun_version)],
        sha256 = "a08f77a490b7f88a9f641df0344373e83763eb92cf502c699fb641db84e5d3ba",
        strip_prefix = "rules_multirun-{}".format(multirun_version),
    )

def org_binary_dependencies():
    """Declare binary tool dependencies."""

    helm_version = "3.12.0"
    maybe(
        http_archive,
        name = "helm",
        urls = ["https://get.helm.sh/helm-v{}-darwin-arm64.tar.gz".format(helm_version)],
        sha256 = "879f61d2ad245cb3f5018ab8b66a87619f195904a4df3b077c98ec0780e36c37",
        strip_prefix = "darwin-arm64",
        build_file = "//bazel/third_party:BUILD.helm.bazel",
    )

    istio_version = "1.17.2"
    maybe(
        http_archive,
        name = "istioctl",
        urls = ["https://github.com/istio/istio/releases/download/{v}/istioctl-{v}-osx-arm64.tar.gz".format(v = istio_version)],
        sha256 = "717595a9f3527f4e6af64378dd79e4cd0f8240501da4b2431102ba8bd48588a9",
        build_file = "//bazel/third_party:BUILD.istioctl.bazel",
    )

    k3d_version = "5.5.1"
    http_file(
        name = "k3d",
        urls = ["https://github.com/k3d-io/k3d/releases/download/v{}/k3d-darwin-arm64".format(k3d_version)],
        sha256 = "891161cd18f5505c8d3eff08344c00ca76f807dfb3d019d119fc1013fe3616ef",
        executable = True,
    )

    kubectl_version = "1.27.2"
    http_file(
        name = "kubectl",
        urls = ["https://dl.k8s.io/release/v{}/bin/darwin/arm64/kubectl".format(kubectl_version)],
        sha256 = "d2b045b1a0804d4c46f646aeb6dcd278202b9da12c773d5e462b1b857d1f37d7",
        executable = True,
    )

def org_manifest_dependencies():
    """Declare Kubernetes manifest dependencies."""

    argocd_version = "2.7.2"
    maybe(
        http_archive,
        name = "argocd",
        urls = ["https://github.com/argoproj/argo-cd/archive/refs/tags/v{}.tar.gz".format(argocd_version)],
        sha256 = "caf989c4a444f514ddb1a4f5307c39d2750c929d9e8dfed8200c35dc2994e403",
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

    kube_prometheus_chart_version = "45.31.0"
    maybe(
        http_archive,
        name = "kube_prometheus",
        urls = ["https://github.com/prometheus-community/helm-charts/releases/download/kube-prometheus-stack-{v}/kube-prometheus-stack-{v}.tgz".format(v = kube_prometheus_chart_version)],
        sha256 = "9f86ce4894f923acd0d90e15b2d1dbfd65dcb1ddbe322440d6ea4f7517172015",
        strip_prefix = "kube-prometheus-stack",
        build_file = "//bazel/third_party:BUILD.kube_prometheus.bazel",
        patch_args = ["-p1"],
        patches = [
            "//bazel/third_party/kube_prometheus:Chart.yaml.patch",
            "//bazel/third_party/kube_prometheus:Chart.lock.patch",
        ],
    )

    grafana_agent_operator_chart_version = "0.2.15"
    maybe(
        http_archive,
        name = "grafana_agent_operator",
        urls = ["https://github.com/grafana/helm-charts/releases/download/grafana-agent-operator-{v}/grafana-agent-operator-{v}.tgz".format(v = grafana_agent_operator_chart_version)],
        sha256 = "f0c525d884fb0a42f0dfad48fc4cf54f07910eec7dbeea7dfadb40b6922a5d50",
        strip_prefix = "grafana-agent-operator",
        build_file = "//bazel/third_party:BUILD.grafana_agent_operator.bazel",
    )

    loki_chart_version = "5.5.4"
    maybe(
        http_archive,
        name = "loki",
        urls = ["https://github.com/grafana/helm-charts/releases/download/helm-loki-{v}/loki-{v}.tgz".format(v = loki_chart_version)],
        sha256 = "46aeb02b13096a1b282ba549580ece32541c1011e46218f1adcc681c4e8dd522",
        strip_prefix = "loki",
        build_file = "//bazel/third_party:BUILD.loki.bazel",
    )

    tempo_chart_version = "1.3.1"
    maybe(
        http_archive,
        name = "tempo",
        urls = ["https://github.com/grafana/helm-charts/releases/download/tempo-{v}/tempo-{v}.tgz".format(v = tempo_chart_version)],
        sha256 = "82d1a955f7a7b63867eacfead139da702aa59912c99cf5b6988f42ae12749949",
        strip_prefix = "tempo",
        build_file = "//bazel/third_party:BUILD.tempo.bazel",
    )

    m3db_operator_chart_version = "0.14.0"
    maybe(
        http_archive,
        name = "m3db_operator",
        urls = ["https://github.com/m3db/m3db-operator/archive/refs/tags/v{}.tar.gz".format(m3db_operator_chart_version)],
        sha256 = "8ea2e29dc659a1eba2fab4aec5466c314a6f174d0b1dab436595fb6c73f8b5c7",
        strip_prefix = "m3db-operator-{}/helm/m3db-operator".format(m3db_operator_chart_version),
        build_file = "//bazel/third_party:BUILD.m3db_operator.bazel",
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

def org_protobuf_dependencies():
    """Declare protobuf dependencies."""

    # Both Protobuf and Grpc need to be managed separately from rules_go. See:
    # https://github.com/bazelbuild/rules_go#protobuf-and-grpc.

    maybe(
        http_archive,
        name = "com_google_protobuf",
        sha256 = "22fdaf641b31655d4b2297f9981fa5203b2866f8332d3c6333f6b0107bb320de",
        strip_prefix = "protobuf-21.12",
        urls = ["https://github.com/protocolbuffers/protobuf/archive/v21.12.tar.gz"],
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
