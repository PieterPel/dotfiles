{ config, lib, ... }:
{
  flake.homeModules.hm-standalone-options = { lib, ... }:
    {
      options.username = lib.mkOption {
        type = lib.types.str;
        description = "The username of the user";
      };
    };
}
