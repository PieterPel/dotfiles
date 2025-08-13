{ inputs
, ...
}:

{
  imports = [
    ../common-options.nix
    ./options.nix
    ./home.nix
    ../programs

    inputs.nixvim.homeManagerModules.nixvim
  ];
}
