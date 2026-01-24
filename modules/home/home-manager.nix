{ inputs, ... }:
let
  mkHomeManagerModule =
    modules:
    { config, lib, ... }:
    let
      cfg = config.modules.home.home-manager;
    in
    {
      options.modules.home.home-manager = {
        enable = lib.mkEnableOption "Enable home-manager module";
      };

      imports = [
        inputs.home-manager.${modules}.default
      ];

      config = lib.mkIf cfg.enable {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";

          # NOTE: Set the correct hostname for all users
          sharedModules = [
            {
              inherit (config) hostname;
            }
          ];
        };
      };
    };
in
{
  flake.modules.nixos.home-manager = mkHomeManagerModule "nixosModules";
  flake.modules.darwin.home-manager = mkHomeManagerModule "darwinModules";
}
