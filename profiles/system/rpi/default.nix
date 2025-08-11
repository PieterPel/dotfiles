{ ...
}:

{
  imports = [
    ./tag.nix
    ./configuration.nix
    ../../../modules/nixos
  ];

  minimal = true;
}
