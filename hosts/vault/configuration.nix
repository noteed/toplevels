# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  sources = import ../../nix/sources.nix;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
      ./disk-config.nix
      "${sources.sops-nix}/modules/sops"
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  networking.hostName = "vault";
  networking.useNetworkd = true;
  networking.networkmanager.enable = false;
  networking.firewall.allowedUDPPorts = [53 67];

  systemd.network.enable = true;

  systemd.network.netdevs = {
    "11-eno0.10" = {
      netdevConfig = {
        Name = "eno0.10";
        Kind = "vlan";
      };
      vlanConfig.Id = 10;
    };
  };

  systemd.network.networks."10-eno0" = {
    enable = true;
    matchConfig.Name = "eno0";
    networkConfig = {
      LinkLocalAddressing = false;
      LLDP = false;
      EmitLLDP = false;
      IPv6AcceptRA = false;
      IPv6SendRA = false;
      VLAN = [ config.systemd.network.netdevs."11-eno0.10".netdevConfig.Name ];
    };
    DHCP = "no";
  };

  systemd.network.links = {
    "20-wan" = {
      enable = true;
      matchConfig = {
        PermanentMACAddress = "64:62:66:2f:30:da";
      };
      linkConfig = {
        Name = "eno0";
        Description = "Ethernet port 1 - WAN";
        AlternativeNamesPolicy = [
          "database"
          "onboard"
          "slot"
          "path"
        ];
        MACAddressPolicy = "none";
        MACAddress = "56:e0:1a:cb:0f:b7";
      };
    };
  };

  # A good chunk of this config is Ramses', while I followed instructions
  # for Proximus customers who have a "Internet box", while I have a
  # "B-box 3". Instead of vlan 20, I need vlan 10 and to run pppd.
  # I guess some options here are not needed and/or wrong.
  systemd.network.networks."12-eno0.10" = {
    enable = true;
    matchConfig.Name =
      config.systemd.network.netdevs."11-eno0.10".netdevConfig.Name;
    DHCP = "yes";
    networkConfig = {
      Description = "Upstream";
      DHCPServer = false;
      DHCPPrefixDelegation = true;
      MulticastDNS = false;
      DNSOverTLS = true;
      IPv6AcceptRA = true;
      IPv6SendRA = false;
    };
    linkConfig = {
      Multicast = true;
    };
    dhcpV4Config = {
      UseDNS = false;
      UseNTP = false;
      UseHostname = false;
    };
    dhcpV6Config = {
      # Workaround for https://github.com/systemd/systemd/issues/31349
      UseAddress = false;
      UseDNS = false;
      UseNTP = false;
      UseHostname = false;

      # We get a /64 over SLAAC from the ISP, but we can additionally
      # assign ourselves a /64 in the /56 that was delegated to use.
      # See the dhcpPrefixDelegation section below where we configure the subnet ID.
      UseDelegatedPrefix = true;
      PrefixDelegationHint = "::/56";

      # Start a DHCPv6 client even if the ISP does not send an RA to initiate
      # WithoutRA = "solicit";
    };
    ipv6AcceptRAConfig = {
      Token = "prefixstable";
      DHCPv6Client = "no";
      UseDNS = false;
    };
    dhcpPrefixDelegationConfig = {
      # This interface is the uplink that needs to obtain the prefix
      UplinkInterface = ":self";
      # We have two different subnets for the two sides of the router,
      # subnet ID 0 for the WAN side and subnet ID 1 for the LAN side.
      SubnetId = 0;
      # No need to announce our prefix to the ISP, they assigned it to us.
      Announce = false;
    };
  };

  systemd.network.networks.wlp4s0 = {
    enable = true;
    matchConfig.Name = "wlp4s0";
    address = [ "192.168.4.1/24" ];
  };

  # Run pppd on top of eno0.10, creating a wan0 interface.
  services.pppd = {
    enable = true;
    peers = {
      proximus = {
        autostart = true;
        enable = true;
        config = ''
          plugin pppoe.so

          eno0.10
          ifname wan0

          persist
          maxfail 0
          holdoff 5

          noaccomp
          default-asyncmap
          mtu 1492

          noipdefault
          defaultroute
        '';
      };
    };
  };

  networking.nat = {
    enable = true;
    internalIPs = [ "192.168.4.0/24" ];
    # Assume wan0 is our WAN. It could be eno0 in a simpler setup.
    externalInterface = "wan0";
  };

  services.haveged.enable = true;

  services.hostapd = {
    enable = true;
    radios.wlp4s0.networks.wlp4s0.ssid = "oh-la-girafe";
    radios.wlp4s0.networks.wlp4s0.authentication.saePasswordsFile =
      config.sops.secrets.passwords.path;
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "wlp4s0";
      bind-interfaces = true;
      dhcp-range = "192.168.4.100,192.168.4.254,24h";
      dhcp-option = "26,1492";
      # Specify Quad9 DNS servers as upstream resolvers
      server = [
        "9.9.9.11"
        "149.112.112.11"
        "2620:fe::11"
        "2620:fe::fe:11"
      ];
    };
  };
  # I still see "dnsmasq: unknown interface wlp4s0" in the logs
  # with this option. Waiting a bit with RestartSec seems to work
  # though.
  systemd.services.dnsmasq.after = [
    "sys-subsystem-net-devices-wlp4s0.device"
  ];
  systemd.services.dnsmasq.serviceConfig.RestartSec = 10;

  time.timeZone = "Europe/Brussels";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  users.users.thu = {
    isNormalUser = true;
    home = "/home/thu";
    extraGroups = [ "wheel" ];
    uid = 1000;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWw6Hpr9E1RyDPgGfFsVmgxfk0SzIkx5vzsq7BxWTLt" # thu on frame
    ];
  };

  security.sudo = {
    enable = true;
    extraRules= [
      {  users = [ "thu" ];
        commands = [
           { command = "ALL" ;
             options= [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  nix.settings.trusted-users = [ "root" "thu" ];

  sops.defaultSopsFile = ../../secrets/hostapd.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.passwords = {};
  sops.secrets.pppoe_username = {
    sopsFile = ../../secrets/pppoe.yaml;
    key = "username";
  };
  sops.secrets.pppoe_password = {
    sopsFile = ../../secrets/pppoe.yaml;
    key = "password";
  };
  # This can be manually copied to /etc/ppp/pap-secrets.
  sops.templates."pppoe-credentials".content = ''
    ${config.sops.placeholder.pppoe_username} * ${config.sops.placeholder.pppoe_password}
  '';
  # This can be manually copied to /etc/ppp/options.
  sops.templates."pppoe-options".content = ''
    name ${config.sops.placeholder.pppoe_username}
  '';

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
