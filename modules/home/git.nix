{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pre-commit
  ];

  programs.lazygit.enable = true;

  programs.git = {
    enable = true;
    userName = "Pieter Pel";
    userEmail = "pelpieter@gmail.com";
  };
}
