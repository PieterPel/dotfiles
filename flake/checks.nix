{ inputs, ... }:
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
      checks = {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            flake-checker.enable = true;
            nixpkgs-fmt.enable = true;
            nil.enable = true;
            statix.enable = true;
          };
        };
      };
    };
}
