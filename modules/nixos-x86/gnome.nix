{ config
, lib
, ...
}:

let
  cfg = config.modules.nixos.gnome;
in
{
  options.modules.nixos-x86.gnome = {
    enable = lib.mkEnableOption "Enable gnome module";
  };

  config = lib.mkIf cfg.enable {
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
