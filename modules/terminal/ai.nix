{
  flake.modules.homeManager.ai =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.ai;
    in
    {
      options.modules.terminal.ai = {
        enable = lib.mkEnableOption "Enable AI terminal configuration.";
      };

      config = lib.mkIf cfg.enable {
        packages = [
          pkgs.amp-cli
        ];
        programs = {
          claude-code.enable = true;
          opencode = {
            enable = true;
            enableMcpIntegration = true;
            settings = {
              plugin = [
                "opencode-gemini-auth@latest"
              ];
            };
          };
          gemini-cli = {
            enable = true;
            settings = {
              selectedAuthType = "oauth-personal";
            };
          };
        };
      };
    };
}
