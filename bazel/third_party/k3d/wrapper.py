"""Wraps k3d to help with Bazel integration."""

import glob
import json
import os
import subprocess
import sys
import time
import yaml

from pathlib import Path

_K3D_BINARY = os.environ.get("00RG_K3D_BINARY")
_K3D_CONFIG = os.environ.get("00RG_K3D_CONFIG")
_KUBECTL_BINARY = os.environ.get("00RG_KUBECTL_BINARY")
_OPERATION = os.environ.get("00RG_OPERATION")
_CLUSTER_NAME = os.environ.get("00RG_CLUSTER")

_K3D_REGISTRY_NAME = "local-registry"
_K3D_REGISTRY_PORT = 5555
_CRD_WAIT_TIME_SECS = 180


def _get_clusters():
    """Get all k3d clusters managed by this repository."""
    res = subprocess.run([_K3D_BINARY, "cluster", "list", "-o=json"], stdout=subprocess.PIPE)
    clusters = json.loads(res.stdout)
    return [c for c in clusters if any("00RG_MANAGED=1" in n["env"] for n in c["nodes"])]


def _cluster_exists():
    """Get whether the specified k3d cluster exists."""
    return any([c["name"] == _CLUSTER_NAME for c in _get_clusters()])


def _registry_exists():
    """Get whether the specified k3d registry exists."""
    res = subprocess.run([_K3D_BINARY, "registry", "list", "-o=json"], stdout=subprocess.PIPE)
    registries = json.loads(res.stdout)
    return any([r["name"] == "k3d-{}".format(_K3D_REGISTRY_NAME) for r in registries])


def create_cluster():
    """Create the k3d cluster if it does not exist."""
    if not _cluster_exists():
        subprocess.run([_K3D_BINARY, "cluster", "create", "--config", _K3D_CONFIG])
        print("Created cluster {}.".format(_CLUSTER_NAME))


def list_clusters():
    """List the k3d clusters managed by this repository."""
    print("Clusters managed by this repository:")
    for cluster in _get_clusters():
        print(cluster["name"])


def _delete_cluster_no_check(cluster_name):
    """Delete the k3d cluster without checking whether it exists."""
    subprocess.run([_K3D_BINARY, "cluster", "delete", cluster_name])
    print("Deleted cluster {}.".format(cluster_name))


def delete_cluster():
    """Delete the k3d cluster if it exists."""
    if _cluster_exists():
        _delete_cluster_no_check(_CLUSTER_NAME)


def delete_all_clusters():
    """Delete all k3d clusters managed by this repository."""
    for cluster in _get_clusters():
        _delete_cluster_no_check(cluster["name"])


def create_registry():
    """Create the k3d image registry if it does not exist."""
    if not _registry_exists():
        subprocess.run([_K3D_BINARY, "registry", "create", _K3D_REGISTRY_NAME, "--port", str(_K3D_REGISTRY_PORT)], stdout=subprocess.DEVNULL)
        print("Created image registry {}:{}.".format(_K3D_REGISTRY_NAME, _K3D_REGISTRY_PORT))


def list_registries():
    """List the k3d registries managed by this repository."""
    print("Registries managed by this repository:")
    if _registry_exists():
        print(_K3D_REGISTRY_NAME)


def delete_registry():
    """Delete the k3d image registry if it exists."""
    if _registry_exists():
        subprocess.run([_K3D_BINARY, "registry", "delete", _K3D_REGISTRY_NAME])
        print("Deleted image registry {}:{}.".format(_K3D_REGISTRY_NAME, _K3D_REGISTRY_PORT))


def _run_wave_hooks(wave_info, hook_type):
    """Run the wave hooks of the specified type."""
    try:
        hooks = wave_info["spec"]["hooks"][hook_type]
    except KeyError:
        return

    for hook in hooks:
        if wait_for_crd_hook := hook.get("waitForCRD"):
            crd = wait_for_crd_hook["name"]
            print("Waiting for CRD {} to exist".format(crd))
            deadline = time.time() + _CRD_WAIT_TIME_SECS
            while time.time() < deadline:
                res = subprocess.run([_KUBECTL_BINARY, "get", "crd", crd], stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
                if res.returncode == 0:
                    time_left = deadline - time.time()
                    res = subprocess.run([_KUBECTL_BINARY, "wait", "--for=condition=established", "--timeout={}s".format(time_left), "crd", crd])
                    if res.returncode != 0:
                        sys.exit("Error waiting for CRD {}".format(crd))
                    return

            sys.exit("Timed out waiting for CRD {}".format(crd))
        else:
            sys.exit("Unrecognized {} wave hook: {}".format(hook_type, json.dumps(hook)))


def _apply_wave(wave_dir):
    """Apply wave of local manifests to the cluster."""
    wave_file = "{}/wave.yaml".format(wave_dir)
    if os.path.exists(wave_file):
        wave_info = yaml.safe_load(Path(wave_file).read_text())

    print("Applying KRM wave: {}".format(wave_dir))
    _run_wave_hooks(wave_info, "preApply")
    subprocess.run([_KUBECTL_BINARY, "apply", "-k", wave_dir])
    _run_wave_hooks(wave_info, "postApply")


def apply_manifests():
    """Apply the KRM manifests to the cluster."""
    cluster_dir = "config/clusters/{}".format(_CLUSTER_NAME)
    if os.path.exists("{}/kustomization.yaml".format(cluster_dir)):
        subprocess.run([_KUBECTL_BINARY, "apply", "-k", cluster_dir])
    else:
        for wave_dir in sorted(glob.glob("{}/wave*".format(cluster_dir))):
            _apply_wave(wave_dir)


match _OPERATION:
    case "apply_manifests":
        apply_manifests()
    case "create_cluster":
        create_registry()
        create_cluster()
        apply_manifests()
    case "list_clusters":
        list_clusters()
    case "delete_cluster":
        delete_cluster()
    case "delete_all_clusters":
        delete_all_clusters()
    case "create_registry":
        create_registry()
    case "list_registries":
        list_registries()
    case "delete_registry":
        delete_registry()
    case "delete_all":
        delete_all_clusters()
        delete_registry()
    case _:
        sys.exit("Unknown operation: {}".format(_OPERATION))
