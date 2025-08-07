{ ...
}:

{
  imports = [
    ../options.nix # Common options
    ./options.nix # HM-specific options
    ./home.nix
  ];
}
