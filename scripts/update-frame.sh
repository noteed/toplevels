#! /usr/bin/env bash

# Update the local machine using the frame configuration.

set -eu

nixpkgs=$(nix-instantiate --eval --expr '(import nix/sources.nix {}).nixpkgs.outPath' | tr -d \")

sudo nixos-rebuild switch \
  -I nixpkgs=$nixpkgs \
  -I nixos-config=/home/thu/projects/toplevels/hosts/frame/configuration.nix
