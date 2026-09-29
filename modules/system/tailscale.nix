let
  # `server` mode pulls in `networking.firewall`, which only exists on NixOS
  # (nix-darwin has no such option, and nixpkgs now validates option paths
  # even inside a false `mkIf`). So nixos and darwin get separate module
  # bodies rather than one shared `mkModule`.
  nixosModule =
    { config, lib, pkgs, ... }:
    let
      cfg = config.modules.system.tailscale;
    in
    {
      options.modules.system.tailscale = {
        enable = lib.mkEnableOption "Enable Tailscale";
        server = lib.mkEnableOption ''
          headless-server networking: Tailscale SSH, client subnet routing, a
          firewall opened for the tailnet (the ports themselves come from
          `tailnet.openPorts`, see modules/system/tailnet.nix), and the base CLI
          tools a remote box needs. Intended for machines administered purely
          over the tailnet (e.g. an external flake's NixOS VM), not desktops'';
      };

      config = lib.mkIf cfg.enable (lib.mkMerge [
        { services.tailscale.enable = true; }

        (lib.mkIf cfg.server {
          environment.systemPackages = with pkgs; [
            curl
            git
            htop
            tailscale
            vim
          ];

          services.tailscale = {
            useRoutingFeatures = "client";
            # Tailscale SSH lets tailnet nodes ssh in per ACL without managing
            # ssh keys. Still gated by a tailnet ACL `ssh` rule — enabling this
            # flag alone grants nothing.
            extraSetFlags = [ "--ssh" ];
          };

          networking.firewall = {
            allowedTCPPorts = [ 22 ];
            allowedUDPPorts = [ 41641 ];
            trustedInterfaces = [ "tailscale0" ];
          };
        })
      ]);
    };

  darwinModule =
    { config, lib, ... }:
    let
      cfg = config.modules.system.tailscale;
    in
    {
      options.modules.system.tailscale = {
        enable = lib.mkEnableOption "Enable Tailscale";
      };

      config = lib.mkIf cfg.enable {
        services.tailscale.enable = true;
      };
    };
in
{
  flake.modules.nixos.tailscale = nixosModule;
  flake.modules.darwin.tailscale = darwinModule;
}
