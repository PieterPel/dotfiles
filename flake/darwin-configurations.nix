{ lib
, flake-parts-lib
, ...
}:
{
  # flake-parts ships options for `nixosConfigurations` but not for
  # `darwinConfigurations`, so the latter lands in the freeform part of the
  # `flake` submodule -- and undeclared freeform outputs cannot be merged
  # across modules. Declaring it here lets each host module under ./hosts
  # contribute its own darwin host, the same way the NixOS hosts already do.
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    darwinConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "nix-darwin configurations, keyed by hostname.";
    };
  };
}
