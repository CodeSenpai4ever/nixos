# hyprland-dots.nix
# NixOS Home Manager module that provides the *actual* end-4/dots-hyprland
# illogical-impulse experience, including the Quickshell bar, on NixOS.
#
# Design principles (Nix philosophy):
#   • Install:   set `dotsHyprland.enable = true` and rebuild.
#   • Uninstall: set `dotsHyprland.enable = false` and rebuild, then
#                optionally `rm -rf ~/.config/quickshell ~/.config/matugen
#                              ~/.config/fuzzel ~/.config/kitty
#                              ~/.config/wlogout ~/.config/hypr`
#
# The dotfiles are fetched from the upstream repo (pinned in flake.lock) and
# copied to $HOME on each `home-manager switch` via a home.activation script,
# making them mutable so that matugen can write generated color files into the
# quickshell config tree at runtime.

{ config, pkgs, inputs, lib, ... }:

let
  cfg  = config.dotsHyprland;
  # The quickshell binary built from the upstream quickshell flake.
  qs   = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Path to the dots-hyprland source tree (pinned in flake.lock).
  src  = inputs.dots-hyprland;
in
{
  # ------------------------------------------------------------------ options
  options.dotsHyprland = {
    enable = lib.mkEnableOption
      "end-4/dots-hyprland illogical-impulse Quickshell desktop";
  };

  # ------------------------------------------------------------------ config
  config = lib.mkIf cfg.enable {

    # -- Packages ---------------------------------------------------------
    home.packages = with pkgs; [
      # ── Quickshell (the bar / widgets) ──────────────────────────────────
      qs

      # ── Color-scheme generation ─────────────────────────────────────────
      matugen

      # ── Wallpaper daemon ────────────────────────────────────────────────
      swww

      # ── Audio ────────────────────────────────────────────────────────────
      cava            # audio visualizer used in the bar
      playerctl       # MPRIS media control
      pavucontrol     # volume control GUI

      # ── Backlight ────────────────────────────────────────────────────────
      brightnessctl   # brightness control
      ddcutil         # external monitor brightness via DDC

      # ── Basic utilities ─────────────────────────────────────────────────
      bc              # math in shell scripts
      cliphist        # clipboard history (used by bar)
      jq              # JSON processing
      xdg-user-dirs   # XDG dir setup
      ripgrep         # fast grep
      wl-clipboard    # wl-copy / wl-paste

      # ── Fonts required by the Quickshell config ──────────────────────────
      # JetBrainsMono NF and Material Symbols are already in home.nix.
      # Additional fonts from the dots-hyprland theme:
      (pkgs.google-fonts.override {
        fonts = [ "Rubik" "Readex Pro" "Space Grotesk" ];
      })
      twemoji-color-font   # emoji fallback

      # ── Themes ───────────────────────────────────────────────────────────
      adw-gtk3             # adw-gtk3 GTK2/3 theme (used by matugen templates)

      # ── Terminal ─────────────────────────────────────────────────────────
      kitty                # terminal referenced in the Hyprland keybinds

      # ── Shell / prompt ───────────────────────────────────────────────────
      starship             # cross-shell prompt (Fish config included)
      eza                  # modern ls with icons

      # ── Hyprland add-ons ─────────────────────────────────────────────────
      hyprsunset           # blue-light filter
      hyprlock             # screen locker
      hypridle             # idle management
      hyprpicker           # color picker

      # ── Screenshots / screen capture ─────────────────────────────────────
      grim                 # screenshot capture
      slurp                # region selection
      swappy               # screenshot annotation
      wf-recorder          # screen recording
      tesseract            # OCR (used by the bar)

      # ── App launcher ─────────────────────────────────────────────────────
      fuzzel               # launcher referenced by the Hyprland keybinds

      # ── Logout / session ─────────────────────────────────────────────────
      wlogout              # logout menu

      # ── Widgets / bar extras ─────────────────────────────────────────────
      imagemagick          # image manipulation (bar scripts)
      libqalculate         # math engine (provides `qalc` for bar search)
      upower               # battery/power info for bar
      wtype                # fake typing (emoji script)
      ydotool              # input automation

      # ── KDE / Plasma utilities (settings dialogs opened by the bar) ──────
      kdePackages.dolphin          # file manager
      kdePackages.bluedevil        # Bluetooth settings
      kdePackages.plasma-nm        # Network settings
      kdePackages.polkit-kde-agent-1  # Polkit authentication agent

      # ── GTK tooling ──────────────────────────────────────────────────────
      nwg-look    # GTK theme/icon switcher
      gtk4
      libadwaita
      uv          # Python venv manager (AI/scripts in the bar)
    ];

    # -- Dotfiles (copied to $HOME on each activation) --------------------
    # We rsync the relevant subdirectories from the pinned dots-hyprland
    # source tree into $HOME.  Using rsync without --update ensures the
    # config always matches the pinned upstream version; user edits will be
    # overwritten on the next `nixos-rebuild switch` (this is intentional –
    # update the pin in flake.lock to pull upstream changes).
    home.activation.installDotsHyprland =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        RSYNC="${pkgs.rsync}/bin/rsync"
        DOTS="${src}/dots"

        # Create destination dirs so rsync can descend into them
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
          "$HOME/.config/quickshell" \
          "$HOME/.config/matugen" \
          "$HOME/.config/hypr" \
          "$HOME/.config/fuzzel" \
          "$HOME/.config/kitty" \
          "$HOME/.config/wlogout" \
          "$HOME/.local/share/icons"

        # Sync each config directory
        $DRY_RUN_CMD $RSYNC -a "$DOTS/.config/quickshell/" "$HOME/.config/quickshell/"
        $DRY_RUN_CMD $RSYNC -a "$DOTS/.config/matugen/"   "$HOME/.config/matugen/"
        $DRY_RUN_CMD $RSYNC -a "$DOTS/.config/hypr/"      "$HOME/.config/hypr/"
        $DRY_RUN_CMD $RSYNC -a "$DOTS/.config/fuzzel/"    "$HOME/.config/fuzzel/"
        $DRY_RUN_CMD $RSYNC -a "$DOTS/.config/kitty/"     "$HOME/.config/kitty/"
        $DRY_RUN_CMD $RSYNC -a "$DOTS/.config/wlogout/"   "$HOME/.config/wlogout/"
        $DRY_RUN_CMD $RSYNC -a "$DOTS/.local/share/icons/" "$HOME/.local/share/icons/"
      '';

    # -- Quickshell systemd service ----------------------------------------
    # Quickshell is launched as a systemd user service that starts with the
    # graphical session (i.e. when Hyprland starts).
    systemd.user.services.quickshell = {
      Unit = {
        Description = "Quickshell illogical-impulse bar";
        After       = [ "graphical-session.target" ];
        PartOf      = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        # `-p ii` selects the ~/.config/quickshell/ii profile
        ExecStart = "${qs}/bin/quickshell -p ii";
        Restart   = "on-failure";
        # Give Hyprland a moment to finish initialising before launching
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
      };
    };

    # -- Wallpaper daemon --------------------------------------------------
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
        # Restore the last wallpaper; the `-` prefix makes failure non-fatal
        # (no stored wallpaper on first boot).
        ExecStartPost = "-${pkgs.swww}/bin/swww restore";
      };
    };

    # -- Hyprland idle / lock ---------------------------------------------
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
  };
}
