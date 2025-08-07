{ pkgs }:
let
  packages = with pkgs; [
    vim
    git
    fastfetch
    comma
  ];
in
{
  inherit packages;
}
