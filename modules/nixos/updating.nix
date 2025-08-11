{ inputs
, lib
, config
, ...
}:

let
  cfg = config.modules.nixos.updating;
in
{
  options.modules.nixos.updating = {
    enable = lib.mkEnableOption "Enable updating module";
  };

  config = lib.mkIf cfg.enable {
    # Automatic updating
    system.autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--update-input"
        "nixpkgs"
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      dates = "02:00";
      randomizedDelaySec = "45min";
    };

  };
}
