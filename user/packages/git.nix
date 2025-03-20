{config, pkgs, ...}:

{
  programs.git = {
    enable = true;
    user = {
      name = "Pieter Pel";
      email = "pelpieter@gmail.com";
    };
  };
}
