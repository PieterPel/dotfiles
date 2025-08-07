{ ... }:
{
  imports = [
    ../minimal
    ./configuration.nix
    ./home-manager.nix
    ./stylix.nix
    ./fonts.nix
    ./virtualization.nix
    ./sops.nix
  ];
}
