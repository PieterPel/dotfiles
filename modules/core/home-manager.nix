{ inputs
, config
, lib
, ...
}:

let
  cfg = config.modules.core.home-manager;
in
{
  options.modules.core.home-manager = {
    enable = lib.mkEnableOption "Enable home-manager module";
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
      };

      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";

      # NOTE: Set the correct hostname for all users
      sharedModules = [
        {
          hostname = config.hostname;
        }
      ];
    };
  };
}
