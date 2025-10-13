{
  flake.modules.homeManager.ai = { config, lib, ... }:
    let
      cfg = config.modules.terminal.ai;
    in
    {
      options.modules.terminal.ai = {
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
    };
}
