{ config, lib, ... }:

let
  cfg = config.modules.nixos.sound;
in
{
  options.modules.nixos.sound = {
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
}
