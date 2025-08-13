{ lib
, pkgs
, config
, ...
}:
{
  config = lib.mkIf config.enableTerminalApps {
    modules.programs = {
      stylix.enable = true;
      fish.enable = true;
      git.enable = true;
    };

    programs.tmux.shell = "${pkgs.fish}/bin/fish";

    programs.btop.enable = true;

    programs.zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
