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
        determinateNix.customSettings = {
          trusted-users = [
            "root"
            "pieterpel"
          ];
          download-buffer-size = 524288000;

          # Let the native Linux builder VM fetch prebuilt deps straight from the
          # binary caches instead of the Mac downloading them and relaying them in.
          # Without this the whole aarch64-linux closure is shuttled host->VM on
          # every build, which is the main reason cross-builds felt slow.
          builders-use-substitutes = true;
        };
      };
    };
}
