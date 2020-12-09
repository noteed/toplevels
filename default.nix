# Example toplevel and net-bootable files.
#
# This contains:
#   - a Folding at home configuration and wrapper script (as an example)
#   - a public SSH key

let
pkgs = import <nixpkgs> {};

folding-at-home-configuration = pkgs.writeTextFile {
  name = "folding-at-home.xml";
  text = ''
    <!-- d -->
    <config>
      <user value='noteed'/>
      <team value='236565'/>
      <passkey value=''\''/>
      <smp value='true'/>
      <gpu value='false'/>
      <slot id='0' type='CPU'>
       <cpus v='64'/>
      </slot>
    </config>
  '';
};

folding-at-home = pkgs.writeScriptBin "folding-at-home" ''
  #! ${pkgs.bash}/bin/bash
  ${pkgs.foldingathome}/bin/FAHClient --config ${folding-at-home-configuration}
'';

os = import <nixpkgs/nixos> {
  configuration = { config, pkgs, lib, ... }: with lib; {
    imports = [
        <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix>
    ];

    # Some useful options for setting up a new system
    services.mingetty.autologinUser = mkForce "root";

    # Enable sshd which gets disabled by netboot-minimal.nix
    systemd.services.sshd.wantedBy = mkOverride 0 [ "multi-user.target" ];

    users.users.root.openssh.authorizedKeys.keys = [
      # A public key from my laptop, to use this image for remote builds.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7BJi0RWBSx3P90qki6+Bbaj+i62twGTD6OZvjJTsWE"
    ];

    nix = {
      # package = pkgs.nixUnstable;
      systemFeatures = [ "recursive-nix" "kvm" "nixos-test" ];
      extraOptions = ''
      '';
    };

    environment.systemPackages = [
      folding-at-home
      pkgs.htop
    ];
  };
};
in
{
  # Build with nix-build -A <attr>

  toplevel = os.config.system.build.toplevel;

  # Netboot-able files that can be served by Pixiecore.
  netboot = pkgs.symlinkJoin {
    name = "netboot";
    paths = [
      os.config.system.build.kernel
      os.config.system.build.netbootRamdisk
      os.config.system.build.netbootIpxeScript
    ];
  };
}
