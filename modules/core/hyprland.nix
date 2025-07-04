{
  config,
  pkgs,
  inputs,
  ...
}:

{
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
    # Wayland
    wayland
    wlroots
    wayland-utils
    wl-clipboard
    firefox-wayland

    # Top bar
    (waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    }))

    # Notifications
    mako
    libnotify

    # Wallpaper
    swww

    # Terminal
    kitty

    # App launcher
    rofi-wayland

    # Logout menu
    wlogout

    # Multimedia
    pw-volume
    playerctl

    # Brightness
    brightnessctl

    # Wifi
    networkmanagerapplet

    # Bluetooth
    blueman

    # Audio
    pavucontrol
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
