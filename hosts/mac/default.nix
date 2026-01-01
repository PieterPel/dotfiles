{ inputs
, config
, ...
}:

let
  hostname = "rebel-pieter";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = {
      self = config.flake;
    };

    modules = builtins.attrValues config.flake.modules.darwin ++ [
      ./_users
      {
        config = {
          inherit hostname;
          system.stateVersion = 6; # Do not change this !
          system.primaryUser = "pieterpel";

          nix.settings.trusted-users = [
            "pieterpel"
          ];

          modules.profiles.full.enable = true;
          modules.package-management.determinate.enable = true;
          modules.security.sops.enable = false;
        };
      }
    ];
  };
}
