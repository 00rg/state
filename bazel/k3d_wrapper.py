"""Wraps k3d to help with Bazel integration."""

import glob
import json
import os
import subprocess
import sys

k3d_binary = os.environ.get("00RG_K3D_BINARY")
k3d_config = os.environ.get("00RG_K3D_CONFIG")
kubectl_binary = os.environ.get("00RG_KUBECTL_BINARY")
operation = os.environ.get("00RG_OPERATION")
cluster_name = os.environ.get("00RG_CLUSTER")

k3d_registry_name = "local-registry"
k3d_registry_port = 5555


def _get_clusters():
    """Get all k3d clusters managed by this repository."""
    res = subprocess.run([k3d_binary, "cluster", "list", "-o=json"], stdout=subprocess.PIPE)
    clusters = json.loads(res.stdout)
    return [c for c in clusters if any("00RG_MANAGED=1" in n["env"] for n in c["nodes"])]


def _cluster_exists():
    """Get whether the specified k3d cluster exists."""
    return any([c["name"] == cluster_name for c in _get_clusters()])


def _registry_exists():
    """Get whether the specified k3d registry exists."""
    res = subprocess.run([k3d_binary, "registry", "list", "-o=json"], stdout=subprocess.PIPE)
    registries = json.loads(res.stdout)
    return any([r["name"] == "k3d-{}".format(k3d_registry_name) for r in registries])


def create_cluster():
    """Create the k3d cluster if it does not exist."""
    if not _cluster_exists():
        subprocess.run([k3d_binary, "cluster", "create", "--config", k3d_config])
        print("Created cluster {}.".format(cluster_name))


def _delete_cluster_no_check(cluster_name):
    """Delete the k3d cluster without checking whether it exists."""
    subprocess.run([k3d_binary, "cluster", "delete", cluster_name])
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
        subprocess.run([k3d_binary, "registry", "create", k3d_registry_name, "--port", str(k3d_registry_port)], stdout=subprocess.DEVNULL)
        print("Created image registry {}:{}.".format(k3d_registry_name, k3d_registry_port))


def delete_registry():
    """Delete the k3d image registry if it exists."""
    if _registry_exists():
        subprocess.run([k3d_binary, "registry", "delete", k3d_registry_name])
        print("Deleted image registry {}:{}.".format(k3d_registry_name, k3d_registry_port))


def apply_manifests():
    """Apply the KRM manifests to the cluster."""
    # print("=======================>")
    # subprocess.run(["pwd"])
    # subprocess.run(["ls", "-la"])
    # subprocess.run(["find", "config"])
    # subprocess.run(["ls", "-la", "config/"])

    cluster_dir = "config/clusters/{}".format(cluster_name)
    if os.path.exists("{}/kustomization.yaml".format(cluster_dir)):
        subprocess.run([kubectl_binary, "apply", "-k", cluster_dir])
    else:
        for wave_dir in sorted(glob.glob("{}/wave*".format(cluster_dir))):
            print("I just found: {}".format(wave_dir))
            # TODO: Apply and then obey wave.yaml (or other way around)
            # subprocess.run([kubectl_binary, "apply", "-k", wave_dir])

match operation:
    case "apply_manifests":
        apply_manifests()
    case "create_cluster":
        create_registry()
        create_cluster()
        apply_manifests()
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
