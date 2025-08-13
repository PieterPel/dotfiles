{ pkgs
, lib
, config
, ...
}:

let
  cfg = config.modules.programs.git;
in
{
  options.modules.programs.git = {
    enable = lib.mkEnableOption "Enable Git configuration.";
  };

  config = lib.mkIf cfg.enable {
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
  };
}

