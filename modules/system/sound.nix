{
  flake.modules.nixos.sound = { config, lib, ... }:
    let
      cfg = config.modules.system.sound;
    in
    {
      options.modules.system.sound = {
        enable = lib.mkEnableOption "Enable sound module";
      };

      config = lib.mkIf cfg.enable {
        # Enable sound with pipewire.
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
      };
    };
}
