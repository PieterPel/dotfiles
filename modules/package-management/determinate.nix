{ inputs, ... }:
{
  flake.modules.darwin.determinate =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.package-management.determinate;
      jq = lib.getExe pkgs.jq;
    in
    {
      imports = [
        inputs.determinate.darwinModules.default
      ];
      options.modules.package-management.determinate = {
        enable = lib.mkEnableOption "Enable determinate-nix configuration";
      };
      config = lib.mkIf cfg.enable {
        nix.enable = lib.mkForce false;
        modules.package-management.nix.enable = lib.mkForce false;
        #determinate-nix.customSettings = {};

      };
    };
}
