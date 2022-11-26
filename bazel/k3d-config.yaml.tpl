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
  create:
    name: "{cluster}-registry"
    host: "0.0.0.0"
    hostPort: "5555"
options:
  k3s:
    extraArgs:
    - arg: --disable=traefik
      nodeFilters:
      - "server:*"
