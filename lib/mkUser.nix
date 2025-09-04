{ pkgs, ... }:

username:

let
  extraNixOs = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "input"
      "networkmanager"
    ];
  };
in
{
  description = username;
  name = username;
  home = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  shell = pkgs.fish;
}
  // (if pkgs.stdenv.isLinux then extraNixOs else { })
