{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pre-commit
    gh
  ];

  programs.lazygit.enable = true;

  programs.git = {
    enable = true;
    userName = "Pieter Pel";
    userEmail = "pelpieter@gmail.com";
  };
}
