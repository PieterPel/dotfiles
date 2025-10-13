{
  flake.modules.homeManager.git = { config, lib, pkgs, ... }:
    let
      cfg = config.modules.terminal.git;
    in
    {
      options.modules.terminal.git = {
        enable = lib.mkEnableOption "Enable Git configuration.";
      };

      config = lib.mkIf cfg.enable {
        packages = with pkgs; [
          pre-commit
          gh
        ];

        programs.git = {
          enable = true;
          userName = "Pieter Pel";
          userEmail = "pelpieter@gmail.com";
        };
      };
    };
}
