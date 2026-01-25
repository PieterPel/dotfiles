{ lib, ... }:
let
  cliProxyApiOverlay = import ../../lib/overlays/cli-proxy-api.nix;
in
{
  flake.modules.nixos.overlays = { config, ... }: {
    config = {
      nixpkgs.overlays = lib.mkAfter [ cliProxyApiOverlay ];
    };
  };

  flake.modules.darwin.overlays = { config, ... }: {
    config = {
      nixpkgs.overlays = lib.mkAfter [ cliProxyApiOverlay ];
    };
  };
}
