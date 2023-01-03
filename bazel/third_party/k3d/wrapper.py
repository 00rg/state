"""Wraps k3d to help with Bazel integration."""

import glob
import json
import os
import subprocess
import sys
import time
import yaml

from pathlib import Path

_K3D_BINARY = os.environ.get("ORG_K3D_BINARY")
_K3D_CONFIG = os.environ.get("ORG_K3D_CONFIG")
_KUBECTL_BINARY = os.environ.get("ORG_KUBECTL_BINARY")
_OPERATION = os.environ.get("ORG_OPERATION")
_CLUSTER_NAME = os.environ.get("ORG_CLUSTER")

_K3D_REGISTRY_NAME = "local-registry"
_K3D_REGISTRY_PORT = 5555
_WAVE_WAIT_TIME_SECS = 300


def _get_clusters():
    """Get all k3d clusters managed by this repository."""
    res = subprocess.run([_K3D_BINARY, "cluster", "list", "-o=json"], stdout=subprocess.PIPE)
    clusters = json.loads(res.stdout)
    return [c for c in clusters if any("ORG_MANAGED=1" in n["env"] for n in c["nodes"])]


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
    deadline = time.time() + _WAVE_WAIT_TIME_SECS

    try:
        wait_for_crds = wave_info["spec"]["hooks"][hook_type]["waitForCRDs"]
    except KeyError:
        wait_for_crds = []

    for crd in wait_for_crds:
        print("Waiting for CRD {} to exist".format(crd))
        while True:
            res = subprocess.run([_KUBECTL_BINARY, "get", "crd", crd], stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
            if res.returncode == 0:
                time_left = deadline - time.time()
                res = subprocess.run([_KUBECTL_BINARY, "wait", "--for=condition=established", "--timeout={}s".format(time_left), "crd", crd], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                if res.returncode == 0:
                    break
                sys.exit("Error waiting for CRD {}: {}".format(crd, res.stdout))
            elif time.time() >= deadline:
                sys.exit("Timed out waiting for CRD {} to exist".format(crd))
            else:
                time.sleep(1)

    try:
        wait_for_rollouts = wave_info["spec"]["hooks"][hook_type]["waitForRollouts"]
    except KeyError:
        wait_for_rollouts = []

    for res in wait_for_rollouts:
        print("Waiting for rollout of {}".format(res))
        splat = res.split("/")
        namespace = splat[0]
        deployment = splat[1]
        time_left = deadline - time.time()
        res = subprocess.run([_KUBECTL_BINARY, "rollout", "status", "-n", namespace, "--timeout={}s".format(time_left), "deployment/{}".format(deployment)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if res.returncode != 0:
            sys.exit("Error waiting for rollout of {}/{}: {}".format(namespace, deployment, res.stdout))


def _kubectl_apply(dir):
    """Use kubectl to server-side apply specified Kustomize directory."""
    res = subprocess.run([_KUBECTL_BINARY, "apply", "--server-side", "-k", dir])
    if res.returncode != 0:
        sys.exit("Error applying Kustomize directory: {}".format(dir))


def _apply_wave(wave_dir):
    """Apply wave of local manifests to the cluster."""
    wave_file = "{}/wave.yaml".format(wave_dir)
    if os.path.exists(wave_file):
        wave_info = yaml.safe_load(Path(wave_file).read_text())

    print("Applying KRM wave: {}".format(wave_dir))
    _run_wave_hooks(wave_info, "preApply")
    _kubectl_apply(wave_dir)
    _run_wave_hooks(wave_info, "postApply")


def apply_manifests():
    """Apply the KRM manifests to the cluster."""
    # If the cluster directory does not contain wave subdirectories, then apply it directly.
    # Otherwise, apply each wave subdirectory in order.
    cluster_dir = "kube/clusters/{}".format(_CLUSTER_NAME)
    if os.path.exists("{}/kustomization.yaml".format(cluster_dir)):
        _kubectl_apply(cluster_dir)
    else:
        for wave_dir in sorted(glob.glob("{}/wave*".format(cluster_dir))):
            _apply_wave(wave_dir)


match _OPERATION:
    case "apply_manifests":
        apply_manifests()
    case "create_cluster":
        create_cluster()
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
