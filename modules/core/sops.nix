{ config, lib, pkgs, ... }:

let
  cfg = config.modules.core.sops;
  wifiSecrets = ../../secrets/wifi.yaml;
in
{
  options.modules.core.sops = {
    enable = lib.mkEnableOption "Enable sops module";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];

    sops = {
      secrets = {
        "wifi/HomeNetwork/password" = {
          sopsFile = wifiSecrets;
        };
      };
    };
  };
}
