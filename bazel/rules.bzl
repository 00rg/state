"""Common rules used by this repository."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

# load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes", "pkg_files")
# load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")
load("@rules_python//python:defs.bzl", "py_binary")

def helm_template(name, tarfile, values_file, release_name, namespace):
    """
    Generates KRM manifests by performing a Helm template operation.

    Args:
      name: Target name
      tarfile: Label name of the chart tarfile
      values_file: Label name of the chart values file
      release_name: Helm release name
      namespace: Namespace to be used
    """
    cmd = """
        $(location @helm//:helm) template \
            {release_name} $(location {tarfile}) \
            --values $(location {values_file}) \
            --namespace {namespace} > $@
    """.format(
        release_name = release_name,
        tarfile = tarfile,
        values_file = values_file,
        namespace = namespace,
    )

    native.genrule(
        name = name,
        srcs = [tarfile, values_file],
        outs = ["{}.yaml".format(name)],
        tools = ["@helm//:helm"],
        cmd = cmd,
    )

def kustomize_build(name, tarfile, dirs):
    """
    Generates KRM manifests by performing a Kustomize build.

    Args:
      name: Target name
      tarfile: Label name of the tarfile that contains the directories to be built
      dirs: List of directory paths within the tarfile
    """
    cmd = """
        tar zxf $(location {tarfile})
        for dir in {dirs}; do
            $(location @kubectl//file) kustomize $$dir
        done > $@
    """.format(
        tarfile = tarfile,
        dirs = " ".join(dirs),
    )

    native.genrule(
        name = name,
        srcs = [tarfile],
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

def generate_manifests(name, manifests):
    """
    Generates third-party KRM manifests into source tree.

    Args:
      name: Target name
      manifests: Dict of target name -> manifest file location
    """
    script = "{}.sh".format(name)
    write_file(
        name = "{}_script".format(name),
        out = script,
        content = [
            "#!/usr/bin/env bash",
        ] + [
            "cp -f {src}.yaml $BUILD_WORKSPACE_DIRECTORY/{dest}".format(
                src = k.lstrip("//:"),
                dest = v,
            )
            for [k, v] in manifests.items()
        ],
    )

    native.sh_binary(
        name = name,
        srcs = [script],
        data = manifests.keys(),
    )

def _k3d_targets(target_prefix, cluster_name):
    """
    Creates create_cluster_xyz and delete_cluster_xyz targets for the specified cluster.

    Args:
      cluster_name: Name of the Kubernetes cluster
      target_prefix: Prefix to be used for created targets
    """
    cluster_id = cluster_name.replace("-", "_")
    k3d_config = "{}_{}_config.yaml".format(target_prefix, cluster_id)
    expand_template(
        name = "{}_config_{}".format(target_prefix, cluster_id),
        out = k3d_config,
        substitutions = {
            "{cluster}": cluster_name,
            "{registry}": "local-registry",
            "{registry_port}": "5555",
        },
        template = "//bazel:k3d-config.yaml.tpl",
    )

    for operation in ["create_cluster", "delete_cluster", "apply_manifests"]:
        py_binary(
            name = "{}_{}_{}".format(target_prefix, operation, cluster_id),
            srcs = ["//bazel:k3d_wrapper.py"],
            main = "//bazel:k3d_wrapper.py",
            env = {
                "00RG_K3D_BINARY": "$(location @k3d//file)",
                "00RG_K3D_CONFIG": "$(location {})".format(k3d_config),
                "00RG_KUBECTL_BINARY": "$(location @kubectl//file)",
                "00RG_OPERATION": operation,
                "00RG_CLUSTER": cluster_name,
            },
            data = ["@k3d//file", "@kubectl//file", ":config", k3d_config],
        )

def k3d_targets(name):
    """
    Creates create_cluster_xyz and delete_cluster_xyz targets for each local cluster.

    Args:
      name: Name used to prefix created targets
    """

    # Names of clusters that are designed to run locally via k3d.
    clusters = [
        paths.basename(d)
        for d in native.glob(
            include = ["config/clusters/init", "config/clusters/*-loc-*"],
            exclude_directories = 0,
        )
    ]

    # Create per-cluster targets.
    for cluster in clusters:
        _k3d_targets(name, cluster)

    # Create general targets.
    for operation in ["create_registry", "delete_registry", "delete_all_clusters", "delete_all"]:
        py_binary(
            name = "{}_{}".format(name, operation),
            srcs = ["//bazel:k3d_wrapper.py"],
            main = "//bazel:k3d_wrapper.py",
            env = {
                "K3D_BINARY": "$(location @k3d//file)",
                "K3D_OPERATION": operation,
            },
            data = ["@k3d//file"],
        )
