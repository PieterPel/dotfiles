{ lib
, pkgs
, config
, ...
}:
{
  config = lib.mkIf config.enableTerminalApps {
    modules.programs = {
      fish.enable = true;
      git.enable = true;
    };
    modules.stylix.enable = true;

    programs.tmux.shell = "${pkgs.fish}/bin/fish";

    programs.btop.enable = true;

    programs.lazygit.enable = true;

    programs.zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
