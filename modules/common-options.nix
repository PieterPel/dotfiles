{ lib, ... }:

{
  # NOTE: these options are shared by NIxOS, Nix-darwin, home-manager module and home-manager standalone!
  options.hostname = lib.mkOption {
    type = lib.types.str;
    description = "The hostname of the system";
  };

  options.minimal = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable a very minimal configuration";
  };
}
