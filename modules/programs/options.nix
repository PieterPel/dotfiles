{ config, lib, ... }:
{
  # This needs to be both homeModule and nixosModule and darwinModule
  flake.homeModules.options-programs = { lib, ... }:
    # Define stuff that can either be set at user level or system level depending on how the module is used
    {
      options = {
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
    };

  flake.nixosModules.options-programs = { lib, ... }:
    {
      options = {
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
    };

  flake.darwinModules.options-programs = { lib, ... }:
    {
      options = {
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
    };
}
