# This configuration is used with scripts/update-frame.sh script.

{
  config,
  lib,
  sources ? import ../../nix/sources.nix,
  pkgs ? import sources.nixpkgs {},
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
    ./disk-config.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # uinput is necessary for kmonad.
  boot.kernelModules = ["uinput"];

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
  services.xserver.dpi = 256;
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

  # TODO The two Xcursor lines don't seem to work, but maybe I need to restart the session.
  # TODO Same for this line:
  # Which is called fonts.optimizeForVeryHighDPI is later version of NixOS.
  services.xserver.displayManager.sessionCommands = ''
    xrdb "${pkgs.writeText "xrdb.conf" ''
      XTerm*faceName:             xft:DejaVu Sans Mono for Powerline:size=8
      XTerm*utf8:                 2

      Xft.dpi: 256
      Xft.autohint: 0
      Xft.lcdfilter: lcddefault
      Xft.hintstyle: hintfull
      Xft.hinting: 1
      Xft.antialias: 1
      Xft.rgba: rgb

      Xcursor.theme: Vanilla-DMZ
      ! Apparently size only works if a theme exists?
      Xcursor.size: 48
    ''}"
  '';

  services.tlp.enable = true;
  services.upower.enable = true;
  systemd.services.upower.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  sound.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  hardware.uinput.enable = true; # For kmonad.

  users.users.thu = {
    isNormalUser = true;
    home = "/home/thu";
    # input, uinput for kmonad.
    # dialout to use minicom against the Protecli Vault, which appears
    # at /dev/ttyUSB0
    extraGroups = [ "wheel" "networkmanager" "uinput" "input" "dialout" ];
    uid = 1000;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    direnv
    firefox
    git
    gnupg
    htop
    mupdf
    pass
    pinentry-curses
    pulseaudio
    ripgrep
    screen
    upower
    vim
  ];

  programs.gnupg.agent.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # services.openssh.enable = true;

  services.physlock.enable = true;
  services.physlock.allowAnyUser = true;

  services.redshift = {
    enable = true;
    temperature = {
      day = 5700;
      night = 3500;
    };
  };
  location.latitude = 50.46;
  location.longitude = 4.86;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  fonts.fontDir.enable = true;
  fonts.enableGhostscriptFonts = true;
  fonts.packages = with pkgs; [
    dejavu_fonts
    google-fonts
    powerline-fonts
  ];

  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
  nix.channel.enable = false;

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
