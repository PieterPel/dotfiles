{ inputs
, config
, ...
}:

let
  hostname = "rebel-pieter-pro";
  system = "aarch64-darwin";

  # `determinate` is deliberately excluded from the darwin module set. Its
  # module imports `inputs.determinate.darwinModules.default` unconditionally
  # (outside the `mkIf cfg.enable`), and that module hard-forces
  # `nix.enable = false`. Setting `modules.package-management.determinate.enable
  # = false` is therefore not enough to get out of its way. This host runs Lix
  # under nix-darwin's own management instead.
  darwinModules = removeAttrs config.flake.modules.darwin [ "determinate" ];
in
{
  flake.darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = {
      self = config.flake;
    };

    modules = builtins.attrValues darwinModules ++ [
      ../mac/_users
      (
        { pkgs, ... }:
        {
          config = {
            inherit hostname;
            system = {
              stateVersion = 6; # Do not change this !
              primaryUser = "pieterpel";
            };

            nix = {
              enable = true;
              package = pkgs.lix;

              settings = {
                trusted-users = [
                  "pieterpel"
                ];

                # `mightyiam/files` uses `|>` in its module definitions, so the
                # evaluating Nix needs pipe operators. determinate.nix sets this
                # for Determinate hosts, but this host excludes that module (see
                # above), so it has to be set here or every rebuild dies with
                # "Pipe operator is disabled". Lix spells the feature singular;
                # Determinate/CppNix wants `pipe-operators`.
                experimental-features = [ "pipe-operator" ];
              };
            };

            modules = {
              profiles.full.enable = true;
              security.sops.enable = false;
            };
          };
        }
      )
    ];
  };
}
