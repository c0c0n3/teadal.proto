Bootstrapping a cluster node
----------------------------
> The real thing...

**TODO**
- very similar to the one-node dev procedure
- master nodes would use the Nix exprs for K8s master
- likewise worker nodes would use the Nix exprs for K8s worker
- for now: follow the same procedure as for the dev box but make it
  secure---firewall, ssh, passwords, K8s certs, etc.
- if we ever need HA, check out: https://github.com/justinas/nixos-ha-kubernetes
