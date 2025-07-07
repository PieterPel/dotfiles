{ lib, ... }:

{
  options.enableDesktopApps = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable desktop applications";
  };
}
