{ config, pkgs, inputs, ... }:

{
  services.xserver.displayManager.gdm.wayland = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  hardware = {
    opengl.enable = true;
    nvidia.modesetting.enable = true;
  };

  environment.systemPackages = [
    # Wayland
    pkgs.wayland
    pkgs.wlroots
    pkgs.wayland-utils

    # Top bar
    (pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    })
    )
    
    # Notifications
    pkgs.mako
    pkgs.libnotify
    
    # Wallpaper
    pkgs.swww
    
    # Terminal
    pkgs.kitty

    # App launcher
    pkgs.rofi-wayland
  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
