{ config, lib, ... }:
let
  cfg = config.modules.programs.ai;
in
{
  options.modules.programs.ai = {
    enable = lib.mkEnableOption "Enable AI terminal configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code.enable = true;
    programs.opencode.enable = true;
    programs.gemini-cli = {
      enable = true;
      settings = {
        selectedAuthType = "oauth-personal";
      };
    };
  };
}
