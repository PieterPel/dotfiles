{ config
, pkgs
, lib
, ...
}:

let
  cfg = config.modules.programs.hyprland;
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    ${lib.getExe pkgs.waybar} &
    ${lib.getExe pkgs.swww} init &
    systemctl --user start hyprpolkitagent &
  '';
in
{
  options.modules.programs.hyprland = {
    enable = lib.mkEnableOption "Enable Hyprland window manager configuration.";
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        exec-once = ''${startupScript}/bin/start'';

        general = {
          "$modifier" = "SUPER";
          gaps_in = 6;
          gaps_out = 8;
          border_size = 2;
          resize_on_border = true;
          "col.active_border" = lib.mkForce "rgb(${config.lib.stylix.colors.base0A})";
          "col.inactive_border" = lib.mkForce "rgb(${config.lib.stylix.colors.base01})";
        };

        monitor = [
          # Laptop below secondary monitor
          "eDP-1,1920x1080@60,0x1080,1.25,bitdepth,10"
          "HDMI-A-1,1920x1080@60,0x0,1,bitdepth,10"
        ];

        workspace = [
          "1,monitor:eDP-1,default:true"
          "2,monitor:eDP-1"
          "3,monitor:eDP-1"
          "4,monitor:eDP-1"
          "5,monitor:eDP-1"

          "6,monitor:HDMI-A-1,default:true"
          "7,monitor:HDMI-A-1"
          "8,monitor:HDMI-A-1"
          "9,monitor:HDMI-A-1"
          "10,monitor:HDMI-A-1"
        ];

        animations = {
          enabled = true;
          bezier = [
            "wind, 0.05, 0.9, 0.1, 1.05"
            "winIn, 0.1, 1.1, 0.1, 1.1"
            "winOut, 0.3, -0.3, 0, 1"
            "liner, 1, 1, 1, 1"
          ];
          animation = [
            "windows, 1, 6, wind, slide"
            "windowsIn, 1, 6, winIn, slide"
            "windowsOut, 1, 5, winOut, slide"
            "windowsMove, 1, 5, wind, slide"
            "border, 1, 1, liner"
            "fade, 1, 10, default"
            "workspaces, 1, 5, wind"
          ];
        };

        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 5;
            passes = 3;
            ignore_opacity = false;
            new_optimizations = true;
          };
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
          };
        };

        misc = {
          # Get rid of the anime stuff
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
      };

      systemd.enable = true;
    };

    services.hyprsunset = {
      enable = true;
      settings = {
        max-gamma = 150;

        profile = [
          {
            time = "7:30";
            identity = true;
          }
          {
            time = "21:00";
            temperature = 5000;
            gamma = 0.8;
          }
        ];
      };
    };
  };
}
