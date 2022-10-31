#!/usr/bin/env bash

set -eou pipefail

usage() {
  cat << EOF
Usage: $(basename "${0}") <DIR>

This script applies the specified directory in waves.

EOF
  exit 1
}

[[ $# != 1 || ! -d "${1}" ]] && usage

base_dir="${1}"

info() {
  local msg="${1}"
  local color_on color_off
  if [[ -n "${TERM:-}" && "${TERM}" != dumb ]]; then
    color_on="$(tput setaf 4)"
    color_off="$(tput sgr0)"
  fi
  printf "\n%s\n" "${color_on:-}${msg}${color_off:-}" >&2
}

run_apply() {
  local dir="${1}"

  run_pre_apply_hooks "${dir}"

  info "Applying ${dir}/kustomization.yaml"
  kustomize build "${dir}" | kubectl apply -f -

  run_post_apply_hooks "${dir}"
}

run_hooks() {
  local wave_file="${1}/wave.yaml"
  local hook_type="${2}"

  [[ ! -f "${wave_file}" ]] && return

  local wave_json total_hooks
  wave_json="$(yq e -o=json "${wave_file}")"
  total_hooks="$(jq ".spec.hooks.${hook_type} | length" <<< "${wave_json}")"
  if ((total_hooks > 0)); then
    info "Running ${hook_type} hooks for ${wave_file}"
  fi

  while read -r hook; do
    block="$(jq -c .waitForCRD <<< "${hook}")"
    if [[ "${block}" != null ]]; then
      IFS=$',' read -r name timeout < <(
        jq -r '[.name, .timeout] | @csv' <<< "${block}" | sed 's/"//g'
      )

      # Make sure the CRD is installed other the call the 'kubectl wait' below
      # will fail. When https://github.com/kubernetes/kubectl/issues/1236 is
      # addressed hopefully this won't be necessary.

      local now deadline
      now="$(date +%s)"
      deadline=$((now + 180))
      while true; do
        if ((now > deadline)); then
          echo >&2 "Timed out waiting for CRD ${name}"
          exit 1
        fi

        echo "Waiting for CRD ${name} to exist"
        if kubectl get "crd/${name}" > /dev/null 2>&1; then
          break
        fi

        sleep 5
        now="$(date +%s)"
      done

      # CRD exists now and so can be waited on.
      kubectl wait \
        --for=condition=established \
        --timeout="${timeout:-120s}" \
        "crd/${name}"

      continue
    fi

    block="$(jq -c .waitForRollout <<< "${hook}")"
    if [[ "${block}" != null ]]; then
      IFS=$',' read -r kind namespace name timeout < <(
        jq -r '[.kind, .namespace, .name, .timeout] | @csv' \
          <<< "${block}" | sed 's/"//g'
      )

      kubectl rollout status \
        --timeout="${timeout:120s}" \
        --namespace="${namespace}" \
        "${kind}/${name}"

      continue
    fi

    echo >&2 "Invalid hook: ${hook}"
    exit 1
  done < <(jq -c "(.spec.hooks.${hook_type} // [])[]" <<< "${wave_json}")
}

run_pre_apply_hooks() {
  run_hooks "${1}" preApply
}

run_post_apply_hooks() {
  run_hooks "${1}" postApply
}

if [[ -f "${base_dir}"/kustomization.yaml ]]; then
  run_apply "${base_dir}"
else
  for wave_dir in "${base_dir}"/*; do
    run_apply "${wave_dir}"
  done
fi
