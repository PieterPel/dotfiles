{config, pkgs, lib, ...}:

{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    style = lib.concatStrings [
      ''
        * {
          font-family: JetBrainsMono Nerd Font Mono;
          font-size: 16px;
          border-radius: 0px;
          border: none;
          min-height: 0px;
        }
        ''
      ];
  };
}
