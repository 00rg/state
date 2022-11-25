#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat << EOF
Usage: $(basename "${0}") EXECUTABLE OPERATION CLUSTER

Wrapper script for k3d.

Arguments:
    EXECUTABLE: Path to the k3d executable
    OPERATION:  One of: create_cluster, delete_cluster
    CLUSTER:    Kubernetes cluster name

EOF
  exit 1
}

# TODO: Pass in jq exe
[[ $# != 3 ]] && usage

k3d_exe="${1}"
operation="${2}"
cluster="${3}"
registry=local-registry
registry_port=5555

create_cluster() {
  if [[ "$("${k3d_exe}" cluster list -o=json | jq 'any(.name == "${cluster}")')" == false ]]; then
    "${k3d_exe}" cluster create "${cluster}" \
	--port 8080:31000@server:0 \
	--port 9080:31001@server:0 \
	--api-port 6443 \
	--k3s-arg "--disable=traefik@server:0" \
	--registry-use "k3d-${registry}:${registry_port}"
    else
      echo "Cluster ${cluster} already exists."
    fi
}

delete_cluster() {
  if [[ "$("${k3d_exe}" cluster list -o=json | jq "any(.name == \"${cluster}\")")" == true ]]; then
    "${k3d_exe}" cluster delete "${cluster}"
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
