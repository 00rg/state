#!/usr/bin/env bash

set -eou pipefail

##
## This script waits until all Deployments and DaemonSets are ready.
##

while IFS=$'\t' read -r kind namespace name; do
  kubectl rollout status -n "${namespace}" "${kind}/${name}" --timeout=3m
done < <(
  kubectl get -A \
    deployments \
    -o=jsonpath="{range .items[*]}{'deployment\t'}{.metadata.namespace}{'\t'}{.metadata.name}{'\n'}{end}"
  kubectl get -A \
    daemonsets \
    -o=jsonpath="{range .items[*]}{'daemonset\t'}{.metadata.namespace}{'\t'}{.metadata.name}{'\n'}{end}"
)
