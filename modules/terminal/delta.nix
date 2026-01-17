let
  parent = "terminal";
  module = "delta";
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.${parent}.${module};
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable ${parent}:${module} configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.delta = {
          enable = true;
          enableGitIntegration = true;
          enableJujutsuIntegration = true;
          options = {
            # General Look
            line-numbers = true;
            side-by-side = true;
            navigate = true; # use 'n' and 'N' to jump between files/diffs

            # Theme & Aesthetics
            syntax-theme = "base16";
            features = "decorations";

            # Decorations (Makes the header look clean)
            decorations = {
              commit-decoration-style = "bold yellow box ul";
              file-style = "bold yellow ul";
              file-decoration-style = "none";
            };
          };
        };
      };
    };
}
