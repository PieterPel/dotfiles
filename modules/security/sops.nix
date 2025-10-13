let
  mkSopsModule = { config, lib, pkgs, ... }:
    let
      cfg = config.modules.security.sops;
      wifiSecrets = ../../secrets/wifi.yaml;
    in
    {
      options.modules.security.sops = {
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
    };
in
{
  flake.modules.nixos.sops = mkSopsModule;
  flake.modules.darwin.sops = mkSopsModule;
}
