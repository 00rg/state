apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: "{cluster}"
servers: 1
agents: 1
ports:
# External ingress gateway
- port: 8080:31000
  nodeFilters:
  - server:0
# Internal ingress gateway
- port: 8081:31001
  nodeFilters:
  - server:0
# Office ingress gateway
- port: 8082:31002
  nodeFilters:
  - server:0
registries:
  use:
  - "{registry}:{registry_port}"
env:
# The Bazel code will only touch clusters that it created. The env var below
# is used to mark the cluster as having been created by this repository.
- envVar: ORG_MANAGED=1
  nodeFilters:
  - "agent:*"
  - "server:*"
options:
  k3s:
    extraArgs:
    - arg: --disable=traefik,metrics-server
      nodeFilters:
      - "server:*"
