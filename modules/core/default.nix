{ ... }:
{
  imports = [
    ../common-options.nix
    ./configuration.nix
    ./home-manager.nix
    ./stylix.nix
    ./fonts.nix
    ./sops.nix
  ];
}
