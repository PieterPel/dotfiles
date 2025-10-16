{ inputs, ... }:
let
  mkSopsModule =
    modules:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.security.sops;
      wifiSecrets = ../../secrets/wifi.yaml;
    in
    {
      options.modules.security.sops = {
        enable = lib.mkEnableOption "Enable sops module";
      };

      imports = [
        inputs.sops-nix.${modules}.default
      ];

      config = lib.mkIf cfg.enable {
        packages = with pkgs; [
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
  flake.modules.nixos.sops = mkSopsModule "nixosModules";
  flake.modules.darwin.sops = mkSopsModule "darwinModules";
}
