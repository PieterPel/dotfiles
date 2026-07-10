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

          # Native Linux builder via macOS's Virtualization framework (Determinate
          # Nix >= 3.8.4): build aarch64-linux / x86_64-linux derivations locally
          # instead of on a slow remote host (e.g. the Pi 400 over --build-host).
          # Enables the external-builders experimental feature and hands the build
          # off to determinate-nixd. Verify with `determinate-nixd version`
          # (lists native-linux-builder) and `nix build nixpkgs#legacyPackages.aarch64-linux.hello`.
          extra-experimental-features = "external-builders";
          external-builders = builtins.toJSON [
            {
              systems = [
                "aarch64-linux"
                "x86_64-linux"
              ];
              program = "/usr/local/bin/determinate-nixd";
              args = [ "builder" ];
            }
          ];
        };
      };
    };
}
