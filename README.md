# Toplevels

In NixOS parlance, the `toplevel` is a complete system, and is really "just" a
path in the Nix store. In a NixOS machine, `/run/current-system` points to the
current toplevel, which is usually built by `nixos-rebuild`.

In Nixpkgs, the `nixos/default.nix` file exposes the toplevel as the `system`
attribute.

This repository contains a test toplevel, to try to build it in a GitHub
action.
