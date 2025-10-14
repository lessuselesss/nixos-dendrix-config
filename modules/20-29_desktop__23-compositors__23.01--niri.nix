# 23.01 Niri Compositor
# Scrollable-tiling Wayland compositor with dynamic workspaces
{ inputs, ... }:

{
  flake.nixosModules.niri = { config, lib, pkgs, ... }: {
    # Enable niri compositor
    programs.niri.enable = true;

    # System packages needed for niri
    environment.systemPackages = with pkgs; [
      niri
      xwayland-satellite  # XWayland support for niri
      fuzzel              # Application launcher
      waybar              # Status bar
      swaylock            # Screen locker
      swayidle            # Idle management
      mako                # Notification daemon
      grim                # Screenshot tool
      slurp               # Region selector
      wl-clipboard        # Clipboard utilities
      kanshi              # Display configuration
    ];

    # XDG portal for screen sharing and other desktop integration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome  # Reuse GNOME portal
        xdg-desktop-portal-gtk
      ];
    };

    # Home-manager configuration for niri
    home-manager.users.lessuseless = { pkgs, config, ... }: {
      # Niri configuration file (KDL format)
      home.file.".config/niri/config.kdl".text = ''
        // Niri configuration in KDL format
        // For full documentation, see: https://github.com/YaLTeR/niri

        input {
            keyboard {
                xkb {
                    layout "us"
                }

                repeat-delay 600
                repeat-rate 25
            }

            touchpad {
                tap
                dwt
                natural-scroll
                accel-speed 0.2
            }

            mouse {
                accel-speed 0.2
            }
        }

        output "eDP-1" {
            mode "1920x1080@60"
            scale 1.0
            transform "normal"
            position x=0 y=0
        }

        layout {
            gaps 8

            center-focused-column "on-overflow"

            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }

            default-column-width { proportion 0.5; }

            focus-ring {
                width 2
                active-color "#7fc8ff"
                inactive-color "#505050"
            }

            border {
                width 1
                active-color "#7fc8ff"
                inactive-color "#505050"
            }
        }

        spawn-at-startup "waybar"
        spawn-at-startup "mako"
        spawn-at-startup "xwayland-satellite"

        prefer-no-csd

        screenshot-path "~/Pictures/Screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png"

        hotkey-overlay {
            skip-at-startup
        }

        environment {
            DISPLAY ":0"
            WAYLAND_DISPLAY "wayland-1"
            QT_QPA_PLATFORM "wayland"
            MOZ_ENABLE_WAYLAND "1"
            XDG_CURRENT_DESKTOP "niri"
            XDG_SESSION_TYPE "wayland"
        }

        binds {
            // Window management
            Mod+H { focus-column-left; }
            Mod+J { focus-window-down; }
            Mod+K { focus-window-up; }
            Mod+L { focus-column-right; }

            Mod+Shift+H { move-column-left; }
            Mod+Shift+J { move-window-down; }
            Mod+Shift+K { move-window-up; }
            Mod+Shift+L { move-column-right; }

            // Workspace navigation
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }

            Mod+Shift+1 { move-window-to-workspace 1; }
            Mod+Shift+2 { move-window-to-workspace 2; }
            Mod+Shift+3 { move-window-to-workspace 3; }
            Mod+Shift+4 { move-window-to-workspace 4; }
            Mod+Shift+5 { move-window-to-workspace 5; }
            Mod+Shift+6 { move-window-to-workspace 6; }
            Mod+Shift+7 { move-window-to-workspace 7; }
            Mod+Shift+8 { move-window-to-workspace 8; }
            Mod+Shift+9 { move-window-to-workspace 9; }

            // Column width adjustment
            Mod+Comma { set-column-width "-10%"; }
            Mod+Period { set-column-width "+10%"; }

            Mod+R { reset-window-height; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }

            // Application launching
            Mod+Return { spawn "alacritty"; }
            Mod+D { spawn "fuzzel"; }
            Mod+Q { close-window; }

            // Screenshots
            Print { screenshot; }
            Mod+Print { screenshot-window; }
            Mod+Shift+Print { screenshot-screen; }

            // Session management
            Mod+Shift+E { quit; }
            Mod+Shift+R { reload-config; }

            // Media keys
            XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
            XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
            XF86AudioMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
            XF86AudioMicMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

            XF86MonBrightnessUp { spawn "brightnessctl" "set" "5%+"; }
            XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
        }

        cursor {
            xcursor-theme "Adwaita"
            xcursor-size 24
        }

        debug {
            render-drm-device "/dev/dri/renderD128"
        }
      '';

      # Waybar configuration for niri
      programs.waybar = {
        enable = true;
        settings = [{
          layer = "top";
          position = "top";
          height = 30;

          modules-left = [ "niri/workspaces" "niri/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "battery" "tray" ];

          "niri/workspaces" = {
            format = "{icon}";
            format-icons = {
              active = "";
              default = "";
            };
          };

          "niri/window" = {
            max-length = 50;
          };

          clock = {
            format = "{:%H:%M %a %d %b}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = " muted";
            format-icons = {
              default = [ "" "" "" ];
            };
            on-click = "pavucontrol";
          };

          network = {
            format-wifi = " {essid}";
            format-ethernet = " {ifname}";
            format-disconnected = "⚠ Disconnected";
            tooltip-format = "{ifname}: {ipaddr}";
          };

          battery = {
            format = "{icon} {capacity}%";
            format-icons = [ "" "" "" "" "" ];
            format-charging = " {capacity}%";
          };

          tray = {
            spacing = 10;
          };
        }];

        style = ''
          * {
            font-family: "Roboto", sans-serif;
            font-size: 13px;
          }

          window#waybar {
            background-color: rgba(30, 30, 46, 0.9);
            color: #cdd6f4;
            border-bottom: 2px solid rgba(127, 200, 255, 0.5);
          }

          #workspaces button {
            padding: 0 8px;
            color: #cdd6f4;
            background-color: transparent;
          }

          #workspaces button.active {
            background-color: rgba(127, 200, 255, 0.3);
            border-radius: 4px;
          }

          #window {
            margin-left: 10px;
            font-weight: bold;
          }

          #clock,
          #pulseaudio,
          #network,
          #battery,
          #tray {
            padding: 0 10px;
            margin: 0 5px;
          }

          #battery.charging {
            color: #a6e3a1;
          }

          #battery.warning:not(.charging) {
            color: #f9e2af;
          }

          #battery.critical:not(.charging) {
            color: #f38ba8;
          }
        '';
      };

      # Mako notification daemon
      services.mako = {
        enable = true;
        backgroundColor = "#1e1e2e";
        textColor = "#cdd6f4";
        borderColor = "#7fc8ff";
        borderRadius = 8;
        defaultTimeout = 5000;
      };

      # Swayidle for automatic screen locking
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 300;
            command = "${pkgs.swaylock}/bin/swaylock -f";
          }
          {
            timeout = 600;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
      };
    };

    # Enable required services
    services.dbus.enable = true;
    security.polkit.enable = true;

    # Display manager integration (optional)
    # Uncomment to add niri as a session option in GDM
    # services.displayManager.sessionPackages = [ pkgs.niri ];
  };
}
