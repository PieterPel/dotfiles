{inputs, ...}:
{
  flake.modules.homeManager.spicetify = { config, lib, pkgs, ... }:
    let
      cfg = config.modules.gui.spicetify;
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];
      options.modules.gui.spicetify = {
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
    };
}
