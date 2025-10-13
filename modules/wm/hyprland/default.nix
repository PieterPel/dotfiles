{
  config,
  ...
}:
{
  flake.modules.wm.hyprland = { config, lib, pkgs, ... }:
    let
      cfg = config.modules.wm.hyprland;
    in
    {
      options.modules.wm.hyprland = {
        enable = lib.mkEnableOption "Enable hyprland module";
      };

      config = lib.mkIf cfg.enable {
        services.displayManager.gdm.wayland = true;

        programs.hyprland = {
          enable = true;
          xwayland = {
            enable = true;
          };
          portalPackage = pkgs.xdg-desktop-portal-hyprland;
        };

        environment.sessionVariables = {
          WLR_NO_HARDWARE_CURSORS = "1";
          NIXOS_OZONE_WL = "1";
        };

        hardware = {
          graphics.enable = true;
          nvidia.modesetting.enable = true;
        };

        environment.systemPackages = with pkgs; [
          wayland
          wlroots
          wayland-utils
          wl-clipboard
          firefox-wayland
          (waybar.overrideAttrs (oldAttrs: {
            mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
          }))
          mako
          libnotify
          swww
          kitty
          rofi
          wlogout
          pw-volume
          playerctl
          brightnessctl
          networkmanagerapplet
          blueman
          pavucontrol
          hyprshade
          hyprpolkitagent
        ];

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        security.pam.services.hyprlock = { };
        programs.hyprlock.enable = true;
      };
    };

  flake.modules.homeManager.hyprland = {lib, ...}: {
    options.modules.wm.hyprland = {
      enable = lib.mkEnableOption "Enable Hyprland window manager configuration.";
    };
    imports = [
      config.flake.modules.homeManager."hyprland-binds"
      config.flake.modules.homeManager."hyprland-config"
    ];
  };
}
