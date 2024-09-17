# Usage:
# nixos-rebuild switch -I nixos-config=/home/thu/projects/toplevels/hosts/frame/configuration.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
    ./disk-config.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "frame";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Brussels";

  environment.variables = {
    EDITOR = "vim";
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console.font = "ter-132n";
  console.keyMap = "us";
  console.packages = with pkgs; [ terminus_font ];
  # console.useXkbConfig = true; # use xkb.options in tty.

  services.displayManager.defaultSession = "none+xmonad";

  services.xserver.enable = true;
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # We provide our xmonad binary, so don't use services.xserver.windowManager.xmonad.enable.
  services.xserver.windowManager.session = [{
    name = "xmonad";
    start = ''
      systemd-cat -t xmonad -- /home/thu/.xmonad/xmonad-x86_64-linux &
      waitPID=$!
    '';
  }];

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
    extraGroups = [ "wheel" "networkmanager" ];
    uid = 1000;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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
