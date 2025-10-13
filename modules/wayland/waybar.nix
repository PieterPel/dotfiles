# Source: ZaneyOS

{
  flake.modules.homeManager.waybar = { config, lib, pkgs, ... }:
    let
      cfg = config.modules.wayland.waybar;
      betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
    in
    {
      options.modules.wayland.waybar = {
        enable = lib.mkEnableOption "Enable Waybar configuration.";
      };

      config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # Configure & Theme Waybar
    programs.waybar = {
      enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          modules-center = [ "hyprland/workspaces" ];
          modules-left = [
            #"custom/startmenu"
            "pulseaudio"
            "cpu"
            "memory"
            #"idle_inhibitor"
          ];
          modules-right = [
            #"custom/hyprbindings"
            "custom/notification"
            "custom/exit"
            "battery"
            "network"
            "bluetooth"
            "tray"
            "clock"
          ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              default = " ";
              active = " ";
              urgent = " ";
            };
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };
          "clock" = {
            format = ''{:L%H:%M}'';
            tooltip = true;
            tooltip-format = "<big>{:%A, %d.%B %Y }</big>\n<tt><small>{calendar}</small></tt>";
          };
          "hyprland/window" = {
            max-length = 22;
            separate-outputs = false;
            rewrite = {
              "" = " 🙈 No Windows? ";
            };
          };
          "memory" = {
            interval = 5;
            format = " {}%";
            tooltip = true;
          };
          "cpu" = {
            interval = 5;
            format = " {usage:2}%";
            tooltip = true;
          };
          "disk" = {
            format = " {free}";
            tooltip = true;
          };
          "network" = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-ethernet = " {bandwidthDownOctets}";
            format-wifi = "{icon} {signalStrength}%";
            format-disconnected = "󰤮";
            tooltip = false;
            on-click = "nm-connection-editor";
          };
          "bluetooth" = {
            format = " 󰂯 ";
            tooltip = false;
            tooltip-format = "Bluetooth Settings";
            on-click = "blueman-manager";
          };
          "tray" = {
            spacing = 12;
          };
          "pulseaudio" = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "sleep 0.1 && pavucontrol";
          };
          "custom/exit" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && wlogout";
          };
          "custom/startmenu" = {
            tooltip = false;
            format = "";
            # exec = "rofi -show drun";
            on-click = "sleep 0.1 && rofi-launcher";
          };
          "custom/hyprbindings" = {
            tooltip = false;
            format = "󱕴";
            on-click = "sleep 0.1 && list-keybinds";
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            tooltip = "true";
          };
          "custom/notification" = {
            tooltip = false;
            format = "{icon} {}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "sleep 0.1 && task-waybar";
            escape = true;
          };
          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󱘖 {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            on-click = "";
            tooltip = false;
          };
        }
      ];
      style = lib.concatStrings [
        ''
          * {
            font-family: JetBrainsMono Nerd Font Mono;
            font-size: 18px;
            border-radius: 0px;
            border: none;
            min-height: 0px;
          }
          window#waybar {
            background: rgba(0,0,0,0);
          }
          #workspaces {
            color: #${config.lib.stylix.colors.base00};
            background: #${config.lib.stylix.colors.base01};
            margin: 4px 4px;
            padding: 5px 5px;
            border-radius: 16px;
          }
          #workspaces button {
            font-weight: bold;
            background: linear-gradient(45deg, #${config.lib.stylix.colors.base0A}, #${config.lib.stylix.colors.base0E}); 
            padding: 0px 5px;
            margin: 0px 3px;
            border-radius: 16px;
            color: #${config.lib.stylix.colors.base00};
            opacity: 0.5;
            transition: ${betterTransition};
          }
          #workspaces button.active {
            font-weight: bold;
            background: linear-gradient(45deg, #${config.lib.stylix.colors.base0A}, #${config.lib.stylix.colors.base0E}); 
            padding: 0px 5px;
            margin: 0px 3px;
            border-radius: 16px;
            /*color: #${config.lib.stylix.colors.base00};*/
            transition: ${betterTransition};
            opacity: 1.0;
            min-width: 40px;
          }
          #workspaces button:hover {
            font-weight: bold;  
            background: linear-gradient(45deg, #${config.lib.stylix.colors.base0A}, #${config.lib.stylix.colors.base0E}); 
            border-radius: 16px;
            color: #${config.lib.stylix.colors.base00};
            opacity: 0.8;
            transition: ${betterTransition};
          }
          tooltip {
            background: #${config.lib.stylix.colors.base00};
            border: 1px solid #${config.lib.stylix.colors.base05};
            border-radius: 12px;
          }
          tooltip label {
            color: #${config.lib.stylix.colors.base05};
          }
          #window, #pulseaudio, #cpu, #memory, #idle_inhibitor {
            font-weight: bold;
            margin: 4px 0px;
            margin-left: 7px;
            padding: 0px 18px;
            background: #${config.lib.stylix.colors.base00};
            color: #${config.lib.stylix.colors.base05};
            border-radius: 8px 8px 8px 8px;
          }
          #idle_inhibitor {
          font-size: 28px;
          }
          #custom-startmenu {
            color: #${config.lib.stylix.colors.base0B};
            background: #${config.lib.stylix.colors.base02};
            font-size: 22px;
            margin: 0px;
            padding: 0px 5px 0px 5px;
            border-radius: 16px 16px 16px 16px;
          }
          #custom-hyprbindings, #network, #battery, #bluetooth
          #custom-notification, #tray, #custom-exit {
            /* font-weight: bold; */
            background: #${config.lib.stylix.colors.base00};
            color: #${config.lib.stylix.colors.base05};
            margin: 4px 0px;
            margin-right: 7px;
            border-radius: 8px 8px 8px 8px;
            padding: 0px 18px;
          }
          #clock {
            font-weight: bold;
            font-size: 16px;
            color: #0D0E15;
            background: linear-gradient(90deg, #${config.lib.stylix.colors.base0E}, #${config.lib.stylix.colors.base0A});
            margin: 0px;
            padding: 0px 5px 0px 5px;
            border-radius: 16px 16px 16px 16px;
          }
        ''
      ];
    };
      };
    };
}
