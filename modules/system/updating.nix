{ inputs, ... }:
let
  nixosModule = { config, lib, ... }:
    let
      cfg = config.modules.system.updating;
    in
    {
      options.modules.system.updating = {
        enable = lib.mkEnableOption "Enable updating module";
      };

      config = lib.mkIf cfg.enable {
        system.autoUpgrade = {
          enable = true;
          flake = inputs.self.outPath;
          flags = [
            "--update-input"
            "nixpkgs"
            "--no-write-lock-file"
            "-L"
          ];
          dates = "02:00";
          randomizedDelaySec = "45min";
        };
      };
    };
in
{
  flake.modules.nixos.updating = nixosModule;
}
