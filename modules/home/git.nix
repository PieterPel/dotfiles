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
}
