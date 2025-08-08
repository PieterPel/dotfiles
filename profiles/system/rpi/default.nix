{ ...

}:

{
  imports = [
    ./tag.nix
    ./configuration.nix

    # We want a very minimal config
    ../../modules/core/configuration.nix
    ../../../modules/core/sops.nix
  ];
}
