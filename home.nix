{ config, pkgs, inputs, lib, ... }:
{
  imports = [ 
    inputs.catppuccin.homeModules.catppuccin
    inputs.spicetify-nix.homeManagerModules.default
  ];

  home.username = "kronii";
  home.homeDirectory = "/home/kronii";
  home.stateVersion = "25.11";

  # ==================================================================
  #                            Packages
  # ==================================================================
  home.packages = [
    # fonts
    pkgs.material-symbols
    pkgs.nerd-fonts._0xproto
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only

    # audio
    pkgs.carla
    pkgs.qjackctl
    pkgs.alsa-utils
    pkgs.lsp-plugins
    pkgs.puredata
    pkgs.meters-lv2
    pkgs.calf

    # comms
    pkgs.teams-for-linux
    pkgs.vesktop
    pkgs.element-desktop

    # util
    pkgs.nwg-displays
    pkgs.docker
    pkgs.docker-compose
    pkgs.fastfetch
    pkgs.hyfetch
    pkgs.wofi
    pkgs.catppuccin-gtk
    pkgs.catppuccin-papirus-folders  # Catppuccin icons ONLY

    # programs    
    pkgs.jetbrains.idea
    inputs.zen-browser.packages.x86_64-linux.default
  ];

  # ==================================================================
  #                            Services
  # ==================================================================
  systemd.user.services.carla = {
    Unit.Description = "Carla";
    Install.WantedBy = [ "default.target" ];

    Service = {
      ExecStart = "${pkgs.carla}/bin/carla  /home/kronii/.config/sound-patch.carxp";
      Restart = "always";
    };
  };

  systemd.user.services.qjackctl = {
    Unit = {
      Description = "QJackCtl on Hyprland WS10 Silent";
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.qjackctl}/bin/qjackctl";
      Restart = "always";
    };
  };


  # ==================================================================
  #                            Programs
  # ==================================================================
  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "Code Senpai";
        email = "code@codesenpai.dev";
      };
      init.defaultBranch = "main";
    };
  };

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };

  programs.spicetify =
  let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in
  {
    enable = true;

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle # shuffle+ (special characters are sanitized out of extension names)
    ];
    enabledCustomApps = with spicePkgs.apps; [
      newReleases
      ncsVisualizer
    ];
    enabledSnippets = with spicePkgs.snippets; [
      rotatingCoverart
      pointer
    ];

     theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
  };


  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
