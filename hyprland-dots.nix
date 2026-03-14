# hyprland-dots.nix
# NixOS Home Manager module that provides the end-4/dots-hyprland experience
# using matshell (a NixOS-native AGS/Astal-based desktop shell with the same
# Material Design aesthetic).
#
# To enable:  set `dotsHyprland.enable = true;` in your home.nix (or wherever
# this module is imported).  To uninstall, set it to false and rebuild.

{ config, pkgs, inputs, lib, ... }:

let
  cfg = config.dotsHyprland;
in
{
  # matshell module must be imported at the top level so its options are
  # available even when dotsHyprland.enable = false.
  imports = [ inputs.matshell.homeManagerModules.default ];

  # ------------------------------------------------------------------ options
  options.dotsHyprland = {
    enable = lib.mkEnableOption "end-4/dots-hyprland style desktop (matshell bar + supporting packages)";

    compositor = lib.mkOption {
      type    = lib.types.enum [ "hyprland" "river" ];
      default = "hyprland";
      description = "Wayland compositor to target.";
    };

    autostart = lib.mkOption {
      type    = lib.types.bool;
      default = true;
      description = "Start the shell bar automatically as a systemd user service.";
    };

    matugenConfig = lib.mkOption {
      type    = lib.types.bool;
      default = true;
      description = "Generate matugen color-scheme config files (GTK, AGS, Hyprland, Hyprlock).";
    };
  };

  # ------------------------------------------------------------------ config
  config = lib.mkIf cfg.enable {

    # -- matshell bar / shell widget set ----------------------------------
    programs.matshell = {
      enable        = true;
      compositor    = cfg.compositor;
      autostart     = cfg.autostart;
      matugenConfig = cfg.matugenConfig;
    };

    # -- Supporting packages ----------------------------------------------
    home.packages = with pkgs; [
      # Colour-scheme generation (required by matshell / matugen)
      matugen

      # Wallpaper daemon with transition effects
      swww

      # Screenshot / screen-capture utilities
      grim
      slurp
      swappy

      # Clipboard manager
      wl-clipboard
      cliphist

      # Screen locker
      hyprlock

      # Notification daemon
      dunst
      libnotify

      # App launcher (complements the matshell built-in launcher)
      rofi-wayland

      # Polkit authentication agent
      polkit_gnome

      # GTK theming utilities
      nwg-look
      gtk4

      # System info
      btop
      pavucontrol
    ];

    # -- Hyprland idle / lock integration ---------------------------------
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd        = "hyprlock";
          before_sleep_cmd = "hyprlock";
          after_sleep_cmd  = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout    = 300;
            on-timeout = "hyprlock";
          }
          {
            timeout    = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    # -- Polkit agent systemd service -------------------------------------
    systemd.user.services.polkit-agent = {
      Unit = {
        Description = "Polkit authentication agent";
        After       = [ "graphical-session.target" ];
        PartOf      = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart   = "on-failure";
      };
    };

    # -- Wallpaper daemon systemd service ---------------------------------
    systemd.user.services.swww-daemon = {
      Unit = {
        Description = "swww wallpaper daemon";
        After       = [ "graphical-session.target" ];
        PartOf      = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart     = "${pkgs.swww}/bin/swww-daemon";
        Restart       = "on-failure";
        ExecStartPost = "-${pkgs.swww}/bin/swww restore";
      };
    };
  };
}
