{ ...
}:

{
  imports = [
    ./tag.nix
    ./networking.nix
    ./configuration.nix
    ../../../modules/nixos
  ];

  minimal = true;
}
