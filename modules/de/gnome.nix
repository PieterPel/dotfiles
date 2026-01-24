{
  flake.modules.nixos.gnome =
    { config, lib, ... }:
    let
      cfg = config.modules.de.gnome;
    in
    {
      options.modules.de.gnome = {
        enable = lib.mkEnableOption "Enable gnome module";
      };

      config = lib.mkIf cfg.enable {
        services.xserver = {
          # Enable the X11 windowing system.
          enable = true;

          # Enable the GNOME Desktop Environment.
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;

          # Configure keymap in X11
          xkb = {
            layout = "us";
            variant = "";
          };
        };
      };
    };
}
