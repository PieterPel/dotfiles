{ lib, ... }:

{
  options.enableDesktopApps = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable desktop applications";
  };

  options.browser = lib.mkOption {
    type = lib.types.string;
    default = "brave";
    description = "Default browser";
  };

  options.explorer = lib.mkOption {
    type = lib.types.string;
    default = "thunar";
    description = "Default file explorer";
  };

  options.terminal = lib.mkOption {
    type = lib.types.string;
    default = "kitty";
    description = "Default terminal";
  };
}
