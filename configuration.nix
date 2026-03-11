{ config, lib, pkgs, ... }:

{
  imports = [
      ./hardware-configuration.nix
      ./audio/pipe-sinks.nix
  ];

  # ==================================================================
  #                          Boot Loader
  # ==================================================================
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true; 

  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.kernelModules = [
    "snd-seq"
    "snd-rawmidi"
  ];

  virtualisation.docker.enable = true;

  # ==================================================================
  #                          Nvidia
  # ==================================================================
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };

  # ==================================================================
  #                          Networking
  # ==================================================================
  networking.networkmanager.enable = true;
  networking.hostName = "ourokronii";
  networking.wireless.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # ==================================================================
  #                          Locale
  # ==================================================================

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };


  # ==================================================================
  #                            Services
  # ==================================================================
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "de-latin1-nodeadkeys";

  # Enable CUPS to print documents.
  services.printing.enable = true;


  services.gnome.gnome-keyring.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ==================================================================
  #                              User
  # ==================================================================
  users.users.kronii = {
    isNormalUser = true;
    description = "kronii";
    extraGroups = [ "networkmanager" "wheel" "audio" "docker" ];
    packages = with pkgs; [
      kdePackages.kate
      kitty
    ];
    shell = pkgs.zsh;
  };

  # ==================================================================
  #                            Programs
  # ==================================================================
   programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 10000;
    shellAliases = {
      ff = "hyfetch";
      hf = "hyfetch";
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
    };
    setOptions = [
      "AUTO_CD"
    ];
    ohMyZsh = {
      enable = true;
      plugins = [
      "git"
      "dirhistory"
      "history"
      ];
      theme= "eastwood";
    };
  };
  users.defaultUserShell = pkgs.zsh;
  system.userActivationScripts.zshrc = "touch .zshrc";
  environment.shells = with pkgs; [ zsh ];

  programs.firefox.enable = true;
  programs.hyprland = {
    enable = true; 
    #withUWSM = true; 
    xwayland.enable  = true;
  };


  # ==================================================================
  #                          Packages
  # ==================================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  ];
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # ==================================================================
  #                         External Drives
  # ==================================================================
  fileSystems."/mnt/win" =
    { device = "/dev/disk/by-uuid/F2FA36A1FA366251";
      fsType = "ntfs";
      options = [
        "uid=1000"
        "gid=100"
        "umask=000"
        "rw"
        "exec"
        "nofail"
      ];
    };
  fileSystems."/mnt/software" =
    { device = "/dev/disk/by-uuid/5EEC39ADEC398077";
      fsType = "ntfs";
      options = [
        "uid=100"
        "gid=100"
        "umask=000"
        "rw"
        "exec"
        "nofail"
      ];
    };
  fileSystems."/mnt/t7" =
    { device = "/dev/disk/by-uuid/76FC-0426";
      fsType = "exfat";
      options = [
        "uid=1000"
        "gid=100"
        "umask=000"
        "rw"
        "exec"
        "nofail"
      ];
    };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
