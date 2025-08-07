{ ...
}:

{
  imports = [
    ../minimal
    ./spicetify.nix
    ./home-manager.nix
    ./stylix.nix
    ./fonts.nix
    ./virtualization.nix
  ];

  programs.firefox.enable = true;
}
