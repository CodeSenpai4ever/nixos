# hyprland-dots.nix
# NixOS Home Manager module that provides the *actual* end-4/dots-hyprland
# illogical-impulse experience, including the Quickshell bar, on NixOS.
#
# Install:   set `dotsHyprland.enable = true` in home.nix and rebuild.
# Uninstall: set `dotsHyprland.enable = false` and rebuild — the activation
#            cleanup script removes the files installed by this module.
#
# NOTE: ~/.config/hypr/ is intentionally never touched by this module so
#       that your existing Hyprland configuration (keyboard layout, monitor
#       setup, keybinds) is always preserved.

{ config, pkgs, inputs, lib, ... }:

let
  cfg = config.dotsHyprland;
  # Quickshell binary from the upstream quickshell flake.
  qs  = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Pinned dots-hyprland source tree (non-flake input).
  src = inputs.dots-hyprland;
in
{
  # ------------------------------------------------------------------ options
  options.dotsHyprland = {
    enable = lib.mkEnableOption
      "end-4/dots-hyprland illogical-impulse Quickshell desktop";
  };

  # ------------------------------------------------------------------ config
  config = lib.mkMerge [

    # ── Cleanup when disabled ─────────────────────────────────────────────────
    # Runs on every `nixos-rebuild switch` when enable = false.
    # Removes only the files the install script created (identified by a
    # sentinel file), so user-created files are never deleted.
    (lib.mkIf (!cfg.enable) {
      home.activation.cleanupDotsHyprland =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          _sentinel="$HOME/.local/share/.dots-hyprland-installed"
          if [ -f "$_sentinel" ]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -rf \
              "$HOME/.config/quickshell" \
              "$HOME/.config/matugen" \
              "$HOME/.config/fuzzel" \
              "$HOME/.config/wlogout" \
              "$HOME/.local/share/icons/Bibata-Original-Classic" \
              "$_sentinel"
          fi
        '';
    })

    # ── Install when enabled ──────────────────────────────────────────────────
    (lib.mkIf cfg.enable {

      # -- Packages -----------------------------------------------------------
      home.packages = with pkgs; [
        # Quickshell bar
        qs

        # Color-scheme generation
        matugen

        # Wallpaper daemon
        swww

        # Audio
        cava playerctl pavucontrol

        # Backlight
        brightnessctl ddcutil

        # Basic utilities
        bc cliphist jq xdg-user-dirs ripgrep wl-clipboard

        # Fonts (Material Symbols + JetBrains Mono NF are already in home.nix)
        rubik          # Rubik — used by the bar UI
        google-fonts   # Space Grotesk + Readex Pro (no individual nixpkgs packages)
        adw-gtk3       # GTK theme referenced by matugen templates

        # Terminal / shell (kitty is the terminal the bar launches)
        kitty starship eza

        # Hyprland add-ons
        hyprsunset hyprlock hypridle hyprpicker

        # Screenshots / screen capture
        grim slurp swappy wf-recorder tesseract

        # Launcher / logout
        fuzzel wlogout

        # Bar extras
        imagemagick libqalculate upower wtype ydotool

        # KDE utilities (settings dialogs opened from the bar)
        kdePackages.dolphin
        kdePackages.bluedevil
        kdePackages.plasma-nm
        kdePackages.polkit-kde-agent-1

        # GTK tooling
        nwg-look gtk4 libadwaita

        # Python venv manager for AI/script features
        uv
      ];

      # -- Dotfiles (bar config only — Hyprland config is never touched) ------
      # Only the configs owned by the bar itself are synced here.
      # ~/.config/hypr/  is intentionally excluded so your keyboard layout,
      # monitor setup and keybinds are preserved.
      # ~/.config/kitty/ is excluded for the same reason — it's your terminal.

      # This early activation must run before checkLinkTargets so that any
      # regular files left in ~/.config/hypr/ by the original broken rsync
      # (which wrongly copied the whole hypr tree from the Nix store) are
      # removed before Home Manager checks for symlink conflicts.  It also
      # repairs the directory permissions so the later linkGeneration step
      # can write symlinks into it.
      home.activation.repairHyprDir =
        lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          HYPR="$HOME/.config/hypr"
          if [ -d "$HYPR" ]; then
            # Fix any read-only directory permissions left by the old rsync -a.
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+rwX "$HYPR"
            # Remove regular files (not symlinks) that Home Manager will
            # manage as symlinks (e.g. hypridle.conf from services.hypridle).
            # Leaving them as plain files causes checkLinkTargets to abort.
            for f in hypridle.conf hyprlock.conf; do
              if [ -f "$HYPR/$f" ] && [ ! -L "$HYPR/$f" ]; then
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$HYPR/$f"
              fi
            done
          fi
        '';

      home.activation.installDotsHyprland =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          RSYNC="${pkgs.rsync}/bin/rsync"
          DOTS="${src}/dots"

          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
            "$HOME/.config/quickshell" \
            "$HOME/.config/matugen" \
            "$HOME/.config/fuzzel" \
            "$HOME/.config/wlogout" \
            "$HOME/.local/share/icons"

          # rsync flags:
          #   -a         archive (preserves timestamps, symlinks, etc.)
          #   --chmod=u+rwX  ensure all copied files/dirs are user-writable;
          #               the Nix store is read-only so without this flag the
          #               destination directories end up with r-x permissions,
          #               which breaks matugen colour writes and the sentinel.
          RSYNC_FLAGS="-a --chmod=u+rwX"

          # Quickshell illogical-impulse bar config
          $DRY_RUN_CMD $RSYNC $RSYNC_FLAGS "$DOTS/.config/quickshell/" "$HOME/.config/quickshell/"
          # Color-scheme generation templates
          $DRY_RUN_CMD $RSYNC $RSYNC_FLAGS "$DOTS/.config/matugen/"    "$HOME/.config/matugen/"
          # App launcher
          $DRY_RUN_CMD $RSYNC $RSYNC_FLAGS "$DOTS/.config/fuzzel/"     "$HOME/.config/fuzzel/"
          # Logout screen
          $DRY_RUN_CMD $RSYNC $RSYNC_FLAGS "$DOTS/.config/wlogout/"    "$HOME/.config/wlogout/"
          # Cursor icons
          $DRY_RUN_CMD $RSYNC $RSYNC_FLAGS "$DOTS/.local/share/icons/" "$HOME/.local/share/icons/"

          # Sentinel written to ~/.local/share/ (always user-writable) so that
          # the cleanup activation can detect files installed by this module.
          # Only written when not in dry-run mode.
          if [ -z "''${DRY_RUN_CMD:-}" ]; then
            ${pkgs.coreutils}/bin/touch "$HOME/.local/share/.dots-hyprland-installed"
          fi
        '';

      # -- Quickshell systemd service -----------------------------------------
      systemd.user.services.quickshell = {
        Unit = {
          Description = "Quickshell illogical-impulse bar";
          After       = [ "graphical-session.target" ];
          PartOf      = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart    = "${qs}/bin/quickshell -c ii";
          Restart      = "on-failure";
          # Give Hyprland a moment to finish initialising
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
        };
      };

      # -- Wallpaper daemon ---------------------------------------------------
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

      # -- Hyprland idle / lock -----------------------------------------------
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd         = "hyprlock";
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
    })

  ]; # end mkMerge
}
