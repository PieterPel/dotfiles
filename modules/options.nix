{ lib, ... }:

{
  options.hostname = lib.mkOption {
    type = lib.types.string;
    description = "The hostname of the system";
  };
}
