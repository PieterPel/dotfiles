{ lib, ... }:

{
  options.username = lib.mkOption {
    type = lib.types.string;
    description = "The username of the user";
  };
}
