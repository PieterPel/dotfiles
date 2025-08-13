{ config
, pkgs
, lib
, ...
}:

let
  cfg = config.modules.programs.zed;
in
{
  options.modules.programs.zed = {
    enable = lib.mkEnableOption "Enable Zed editor configuration.";
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; ([
      # There is a home-manager module but it sucks
      zed-editor

      # These are to get LSPs workihg nicely
      rust-analyzer
      ruff
      nil
      basedpyright
    ]);
  };
}
