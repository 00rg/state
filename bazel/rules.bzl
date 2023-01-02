"""Common rules used by this repository."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_python//python:defs.bzl", "py_binary")

def helm_template(name, chart_dir, release_name, srcs = [], namespace = None, values_file = None, include_crds = False):
    """
    Generates KRM manifests by performing a Helm template operation.

    Args:
      name: Target name
      chart_dir: Path to chart directory
      release_name: Helm release name
      srcs: Files to be added to genrule srcs
      namespace: Namespace to be used
      values_file: Label name of the chart values file
      include_crds: Whether CRDs should also be exported
    """

    args = [
        "$(location @helm//:helm)",
        "template",
        release_name,
        chart_dir,
    ]

    if values_file:
        args.extend(["--values", "$(location {})".format(values_file)])
        srcs.append(values_file)

    if namespace:
        args.extend(["--namespace", namespace])

    if include_crds:
        args.append("--include-crds")

    # Stderr is silenced due to https://github.com/helm/helm/issues/7019. We could
    # filter it through grep but then the grep binary would need to be a dependency
    # to keep things hermetic which doesn't seem worth it.
    cmd = "{} > $@ 2> /dev/null".format(" ".join(args))

    native.genrule(
        name = name,
        srcs = srcs,
        outs = ["{}.yaml".format(name)],
        tools = ["@helm//:helm"],
        cmd = cmd,
    )

def kustomize_build(name, dirs, srcs):
    """
    Generates KRM manifests by performing a Kustomize build.

    Args:
      name: Target name
      dirs: List of directory paths to build
      srcs: Labels to be added to genrule srcs
    """

    # The --load-restrictor option needs to be specified to work around this issue:
    # https://github.com/kubernetes-sigs/kustomize/issues/4420
    cmd = """
        for dir in {dirs}; do
            $(location @kubectl//file) kustomize $$dir --load-restrictor=LoadRestrictionsNone
        done > $@
    """.format(
        dirs = " ".join(dirs),
    )

    native.genrule(
        name = name,
        srcs = srcs,
        outs = ["{}.yaml".format(name)],
        tools = ["@kubectl//file"],
        cmd = cmd,
    )

def istio_operator(name):
    """
    Generates the KRM manifests required to install Istio Operator.

    Args:
      name: Target name
    """
    cmd = "$(location @istioctl//:istioctl) operator dump > $@"

    native.genrule(
        name = name,
        srcs = [],
        outs = ["{}.yaml".format(name)],
        tools = ["@istioctl//:istioctl"],
        cmd = cmd,
    )

def update_third_party_manifests(name, manifests):
    """
    Updates/installs third-party KRM manifests into source tree.

    Args:
      name: Target name
      manifests: Dict of target name -> manifest file location
    """
    commands = [
        """
        cp -f {src} $BUILD_WORKSPACE_DIRECTORY/{dest}
        chmod 644 $BUILD_WORKSPACE_DIRECTORY/{dest}
        echo Installed {dest}
        """.format(
            # The expression below converts the label name to a YAML file
            # name and handles both //:bar and //foo:bar.
            src = k.lstrip("//").lstrip(":").replace(":", "/") + ".yaml",
            dest = v,
        )
        for [k, v] in manifests.items()
    ]

    script = "{}.sh".format(name)

    write_file(
        name = "{}_script".format(name),
        out = script,
        content = [
            "#!/usr/bin/env bash",
        ] + commands,
    )

    native.sh_binary(
        name = name,
        srcs = [script],
        data = manifests.keys(),
    )

def _k3d_binary(name, env, data):
    """Declare k3d binary target."""
    py_binary(
        name = name,
        srcs = ["//bazel/third_party/k3d:wrapper.py"],
        main = "//bazel/third_party/k3d:wrapper.py",
        env = env,
        data = data,
        deps = ["@yaml//:lib"],
    )

def _k3d_cluster_targets(cluster_name):
    """
    Create k3d cluster targets.

    Args:
      cluster_name: Name of the Kubernetes cluster
    """
    cluster_id = cluster_name.replace("-", "_")
    k3d_config = "{}_config.yaml".format(cluster_id)
    expand_template(
        name = "{}_config".format(cluster_id),
        out = k3d_config,
        substitutions = {
            "{cluster}": cluster_name,
            "{registry}": "local-registry",
            "{registry_port}": "5555",
        },
        template = "//bazel/third_party/k3d:config.yaml.tpl",
    )

    for operation in ["create_cluster", "delete_cluster", "apply_manifests"]:
        _k3d_binary(
            name = "{}_{}".format(operation, cluster_id),
            env = {
                "ORG_K3D_BINARY": "$(location @k3d//file)",
                "ORG_K3D_CONFIG": "$(location {})".format(k3d_config),
                "ORG_KUBECTL_BINARY": "$(location @kubectl//file)",
                "ORG_OPERATION": operation,
                "ORG_CLUSTER": cluster_name,
            },
            data = [
                "@k3d//file",
                "@kubectl//file",
                # TODO: There must be a better way to express that everything under config/
                # is a data dependency of these tasks...
                ":clusters",
                ":components",
                ":platform",
                ":services",
                k3d_config,
            ],
        )

def k3d_targets(cluster_dirs):
    """
    Creates k3d-related targets.

    Args:
      cluster_dirs: Cluster directory glob inclusions
    """

    # Names of clusters that are designed to run locally via k3d.
    clusters = [
        paths.basename(d)
        for d in native.glob(
            include = cluster_dirs,
            exclude_directories = 0,
        )
    ]

    # Create per-cluster targets.
    for cluster in clusters:
        _k3d_cluster_targets(cluster)

    # Create general targets.
    for operation in ["list_clusters", "delete_all_clusters", "delete_all", "create_registry", "delete_registry", "list_registries"]:
        _k3d_binary(
            name = operation,
            env = {
                "ORG_K3D_BINARY": "$(location @k3d//file)",
                "ORG_OPERATION": operation,
            },
            data = ["@k3d//file"],
        )
