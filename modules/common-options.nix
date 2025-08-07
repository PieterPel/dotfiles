{ lib, ... }:

{
  # NOTE: these optoins are shared by NIxOS, Nix-darwin, home-manager module and home-manager standalone!
  options.hostname = lib.mkOption {
    type = lib.types.string;
    description = "The hostname of the system";
  };
}
