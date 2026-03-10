{ config, pkgs, inputs, lib, ... }:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "kronii";
  home.homeDirectory = "/home/kronii";

  imports = [ 
    inputs.catppuccin.homeModules.catppuccin
    inputs.spicetify-nix.homeManagerModules.default
    inputs.matshell.homeManagerModules.default
  ];
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.


  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    pkgs.hello
    pkgs.jetbrains.idea
    pkgs.oh-my-zsh
    pkgs.nwg-displays
    pkgs.teams-for-linux
    pkgs.vesktop
    pkgs.docker
    pkgs.docker-compose

    pkgs.qjackctl
    pkgs.alsa-utils
    pkgs.carla
    pkgs.lsp-plugins
    pkgs.puredata
    pkgs.meters-lv2
    pkgs.calf

	pkgs.ags
	pkgs.material-symbols
	pkgs.nerd-fonts._0xproto
	pkgs.nerd-fonts.jetbrains-mono
	pkgs.nerd-fonts.symbols-only
	pkgs.fastfetch
	pkgs.hyfetch

    pkgs.catppuccin-gtk
    pkgs.catppuccin-papirus-folders  # Catppuccin icons ONLY

    inputs.zen-browser.packages.x86_64-linux.default
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/kronii/etc/profile.d/hm-session-vars.sh
  #
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

  home.sessionVariables = {
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


  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
