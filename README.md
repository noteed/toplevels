# Toplevels

In NixOS parlance, the `toplevel` is a complete system, and is really "just" a
path in the Nix store. In a NixOS machine, `/run/current-system` points to the
current toplevel, which is usually built by `nixos-rebuild`.

In Nixpkgs, the `nixos/default.nix` file exposes the toplevel as the `system`
attribute.

This repository contains a test toplevel, to try to build it in a GitHub
action, and cache it to Backblaze B2.


# Notes

Building, including downloading from cache.nixos.org, takes about 100 seconds.
Uploading everything to B2 took about 14 minutes the first time. Next uploads
take about 50 seconds.

Playing with a binary cache may reuse cached data in `/root/.cache/nix`,
resulting in `does not contain a valid signature`, even though `nix path-info
--sigs ... --store ...` seems fine. Deleting the cache solves the problem.

Backblaze "Daily Class B Transactions Caps" seems to be impacted by simply
uploading the narinfos to it (I guess that some metadata are downloaded to
check if the uploads should actually happen).
