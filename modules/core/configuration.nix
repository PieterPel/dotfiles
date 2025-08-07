{ ...
}:

{
  imports = [
    ../minimal
    ./home-manager.nix
    ./stylix.nix
    ./fonts.nix
    ./virtualization.nix
    ./sops.nix
  ];

  programs.firefox.enable = true;
}
