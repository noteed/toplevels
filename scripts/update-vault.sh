#! /usr/bin/env bash

# Update the Protectli Vault machine.

set -eu

nixpkgs=$(nix-instantiate --eval --expr '(import nix/sources.nix {}).nixpkgs.outPath' | tr -d \")

nixos-rebuild switch \
  --target-host root@192.168.0.26 \
  -I nixpkgs=$nixpkgs \
  -I nixos-config=/home/thu/projects/toplevels/hosts/vault/configuration.nix