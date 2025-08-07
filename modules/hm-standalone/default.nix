{ inputs
, ...
}:
{
  imports = [
    ./options.nix
    ./home.nix
    ../home
    # Stylix has both a NixOS module and a home-manager module, not having the former
    # requires us to do some stuff double
    inputs.stylix.homeModules.stylix
  ];
}
