{
  lib,
  ...
}:
let
  commonOptions = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "The hostname of the system";
    };
    minimal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable a very minimal configuration";
    };
    enableTerminalApps = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable terminal applications";
    };
    enableDesktopApps = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable desktop applications";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages to add to home.packages or environment.systemPackages";
    };
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Shell command aliases.";
    };
    envVars = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables.";
    };
  };
in
{
  flake.modules.nixos.common-options = { options = commonOptions; };
  flake.modules.darwin.common-options = { options = commonOptions; };
  flake.modules.homeManager.common-options = { options = commonOptions; };
}
