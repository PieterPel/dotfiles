{ config
, pkgs
, inputs
, lib
, ...
}:

let
  cfg = config.modules.programs.spicetify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in
{
  options.modules.programs.spicetify = {
    enable = lib.mkEnableOption "Enable Spicetify configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        shuffle # shuffle+ (special characters are sanitized out of extension names)
      ];
    };
  };
}
