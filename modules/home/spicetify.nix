{ config
, pkgs
, inputs
, ...
}:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in
{
  programs.spicetify = {
    enable = config.enableDesktopApps;
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      shuffle # shuffle+ (special characters are sanitized out of extension names)
    ];
  };
}
