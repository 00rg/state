#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat << EOF
Usage: $(basename "${0}") CLUSTER OPERATION EXE_PATH CONFIG_PATH

Wrapper script that helps with calling k3d from Bazel.

Arguments:
    CLUSTER:     Name of the Kubernetes cluster
    OPERATION:   One of: create_cluster, delete_cluster
    EXE_PATH:    Path to the k3d executable file
    CONFIG_PATH: Path to the k3d config file
EOF
  exit 1
}

[[ $# != 4 ]] && usage

cluster="${1}"
operation="${2}"
k3d_exe="${3}"
config="${4}"

cluster_exists() {
  if "${k3d_exe}" cluster list --no-headers | grep -q "^${cluster}\s"; then
    return 0
  fi

  return 1
}

create_cluster() {
  if ! cluster_exists; then
    "${k3d_exe}" cluster create --config "${config}"
  else
    echo "Cluster ${cluster} already exists."
  fi
}

delete_cluster() {
  if cluster_exists; then
    "${k3d_exe}" cluster delete --config "${config}"
  else
    echo "Cluster ${cluster} does not exist."
  fi
}

case "${operation}" in
  create_cluster) create_cluster ;;
  delete_cluster) delete_cluster ;;
  *)
    echo "Unknown operation: ${operation}"
    exit 1
    ;;
esac
