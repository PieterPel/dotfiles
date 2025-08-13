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
  };
}
