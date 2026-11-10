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
            unset DEVELOPER_DIR
          '';
        };
      };
    };

}
