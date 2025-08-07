{ pkgs }:
let
  packages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    base16-schemes
    fastfetch
    comma
  ];
in
{
  inherit packages;
}
