"""Wraps k3d to help with Bazel integration."""

import json
import os
import subprocess
import sys


def env_var_or_panic(name):
    """Get the environment variable value or exit with an error."""
    value = os.environ.get(name)
    if not value:
        sys.exit("Environment variable {} must be specified".format(name))

    return value


binary = env_var_or_panic("K3D_BINARY")
operation = env_var_or_panic("K3D_OPERATION")
cluster_name = os.environ.get("K3D_CLUSTER")
config_file = os.environ.get("K3D_CONFIG")

registry_name = "local-registry"
registry_port = 5555


def _get_clusters():
    """Get all k3d clusters managed by this repository."""
    res = subprocess.run([binary, "cluster", "list", "-o=json"], stdout=subprocess.PIPE)
    clusters = json.loads(res.stdout)
    return [c for c in clusters if any("00RG_MANAGED=1" in n["env"] for n in c["nodes"])]


def _cluster_exists():
    """Get whether the specified k3d cluster exists."""
    return any([c["name"] == cluster_name for c in _get_clusters()])


def _registry_exists():
    """Get whether the specified k3d registry exists."""
    res = subprocess.run([binary, "registry", "list", "-o=json"], stdout=subprocess.PIPE)
    registries = json.loads(res.stdout)
    return any([r["name"] == "k3d-{}".format(registry_name) for r in registries])


def create_cluster():
    """Create the k3d cluster if it does not exist."""
    if not _cluster_exists():
        subprocess.run([binary, "cluster", "create", "--config", config_file])
        print("Created cluster {}.".format(cluster_name))


def _delete_cluster_no_check(cluster_name):
    """Delete the k3d cluster without checking whether it exists."""
    subprocess.run([binary, "cluster", "delete", cluster_name])
    print("Deleted cluster {}.".format(cluster_name))


def delete_cluster():
    """Delete the k3d cluster if it exists."""
    if _cluster_exists():
        _delete_cluster_no_check(cluster_name)


def delete_all_clusters():
    """Delete all k3d clusters managed by this repository."""
    for cluster in _get_clusters():
        _delete_cluster_no_check(cluster["name"])


def create_registry():
    """Create the k3d image registry if it does not exist."""
    if not _registry_exists():
        subprocess.run([binary, "registry", "create", registry_name, "--port", str(registry_port)], stdout=subprocess.DEVNULL)
        print("Created image registry {}:{}.".format(registry_name, registry_port))


def delete_registry():
    """Delete the k3d image registry if it exists."""
    if _registry_exists():
        subprocess.run([binary, "registry", "delete", registry_name])
        print("Deleted image registry {}:{}.".format(registry_name, registry_port))


match operation:
    case "create_cluster":
        create_registry()
        create_cluster()
    case "delete_cluster":
        delete_cluster()
    case "delete_all_clusters":
        delete_all_clusters()
    case "create_registry":
        create_registry()
    case "delete_registry":
        delete_registry()
    case "delete_all":
        delete_all_clusters()
        delete_registry()
    case _:
        sys.exit("Unknown operation: {}".format(operation))
