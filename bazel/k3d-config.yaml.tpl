apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: "{cluster}"
servers: 1
agents: 1
ports:
- port: 8080:31000
  nodeFilters:
  - server:0
- port: 9080:31001
  nodeFilters:
  - server:0
registries:
  use:
  - "{registry}:{registry_port}"
env:
# The Bazel code will only touch clusters that it created. The env var below
# is used to mark the cluster as having been created by this repository.
- envVar: 00RG_MANAGED=1
  nodeFilters:
  - "agent:*"
  - "server:*"
