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
            nixpkgs-fmt.enable = true;
          };
        };
      };
    };
}
