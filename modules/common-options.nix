{ config, lib, ... }:
{
  # NOTE: these options are shared by NIxOS, Nix-darwin, home-manager module and home-manager standalone!
  flake.nixosModules.common-options = { lib, ... }:
    {
      options.hostname = lib.mkOption {
        type = lib.types.str;
        description = "The hostname of the system";
      };

      options.minimal = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable a very minimal configuration";
      };
    };

  flake.darwinModules.common-options = { lib, ... }:
    {
      options.hostname = lib.mkOption {
        type = lib.types.str;
        description = "The hostname of the system";
      };

      options.minimal = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable a very minimal configuration";
      };
    };

  flake.homeModules.common-options = { lib, ... }:
    {
      options.hostname = lib.mkOption {
        type = lib.types.str;
        description = "The hostname of the system";
      };

      options.minimal = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable a very minimal configuration";
      };
    };
}
