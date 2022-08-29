#!/usr/bin/env bash

set -eou pipefail

##
## Wait until all Deployments and DaemonSets are ready.
##
printf "Waiting on workloads to be ready...\n"
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

##
## Wait until Istio is ready.
##
istio_installed="$(kubectl get crds -o json \
  | jq 'any(.items[]; .metadata.name == "istiooperators.install.istio.io")')"
if [[ "${istio_installed}" == true ]]; then
  while IFS=$'\t' read -r namespace name; do
    printf "\nWaiting on IstioOperator %s in namespace %s to be ready...\n" "${name}" "${namespace}"
    # Would much prefer to use `kubectl wait --for=jsonpath=...` but until
    # https://github.com/kubernetes/kubectl/issues/1236 is resolved it's kinda pointless
    # as I'd need to stick it inside a loop and test for error conditions, etc.
    retries=60
    while true; do
      status="$(kubectl get -n "${namespace}" "istiooperator/${name}" -o=jsonpath='{.status.status}')"
      case "${status}" in
        HEALTHY) echo "IstioOperator ${name} in namespace ${namespace} is ready."; break ;;
        ERROR) echo "IstioOperator ${name} in namespace ${namespace} has errors."; exit 1 ;;
        *) ;;
      esac

      sleep 3
      retries=$((retries - 1))
      if ((retries <= 0)); then
        echo "Timed out waiting for IstioOperator ${name} in namespace ${namespace}."
        exit 1
      fi
    done
  done < <(
    kubectl get -A \
      istiooperator \
      -o=jsonpath="{range .items[*]}{.metadata.namespace}{'\t'}{.metadata.name}{'\n'}{end}"
  )
fi
