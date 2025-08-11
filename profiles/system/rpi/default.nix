{ ...
}:

{
  imports = [
    ./tag.nix
    ./configuration.nix

    # We want a very minimal config
    ../../../modules/common-options.nix
    ../../../modules/core/configuration.nix
    ../../../modules/core/sops.nix
    ../../../modules/core/nix.nix
    ../../../modules/nixos/configuration.nix
    ../../../modules/nixos/internationalization.nix
    ../../../modules/nixos/updating.nix
    ../../../modules/nixos/sound.nix
    ../../../modules/nixos/virtualization.nix
  ];
}
