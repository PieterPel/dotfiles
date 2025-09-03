{ pkgs, ... }:

username: {
  description = username;
  name = username;
  home = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  shell = pkgs.fish;
}
