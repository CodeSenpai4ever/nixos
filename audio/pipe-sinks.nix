{ config, lib, pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber = {
      enable = true;
      extraConfig = {
        "routing" = {
          "default.rules" = [
            {
              matches = [
                {
                  "node.name" = "Desktop";
                }
              ];
            }
          ];
        };
      };
    };
	  extraConfig.pipewire."10-virt-sinks" = {
      "context.modules" = [
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.name" = "Desktop";
            "node.description" = "Desktop";
            "audio.channels" = "2";

            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "node.visible" = "true";
              "priority.session" = 2000;
            };

            "playback.props" = {
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
            };
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.name" = "Media";
            "node.description" = "Media";
            "audio.channels" = "2";

            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "node.visible" = "true";
              "priority.session" = 2000;
            };

            "playback.props" = {
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "priority.session" = 2000;
            };
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.name" = "Communication";
            "node.description" = "Communication";
            "audio.channels" = "2";

            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "node.visible" = "true";
              "priority.session" = 2000;
            };

            "playback.props" = {
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "priority.session" = 2000;
            };
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.name" = "Spotify";
            "node.description" = "Spotify";
            "audio.channels" = "2";

            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "node.visible" = "true";
              "priority.session" = 2000;
            };

            "playback.props" = {
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "priority.session" = 2000;
            };
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.name" = "Browser";
            "node.description" = "Browser";
            "audio.channels" = "2";

            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "node.visible" = "true";
              "priority.session" = 2000;
            };

            "playback.props" = {
              "node.autoconnect" = "false";
              "node.dont-fallback" = "true";
              "priority.session" = 2000;
            };
          };
        }
      ];
    };
  };
}
