{ config, lib, ... }:

let
  cfg = config.modules.nixos.networking;
in
{
  options.modules.nixos.networking = {
    enable = lib.mkEnableOption "Enable networking module";
  };

  config = lib.mkIf cfg.enable {
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networking.networkmanager.enable = true;
    networking.wireless.enable = true;
  };
}


