{
  perSystem =
    { config
    , self'
    , inputs'
    , pkgs
    , system
    , ...
    }:
    {
      devShells = {
        default = pkgs.mkShell {
          shellHook = ''
            ${config.checks.pre-commit-check.shellHook}
            unset DEVELOPER_DIR
          '';
          buildInputs = config.checks.pre-commit-check.enabledPackages;
        };
      };
    };

}
