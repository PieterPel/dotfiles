let
  mkModule =
    { config, lib, pkgs, ... }:
    let
      cfg = config.modules.system.tailscale;
    in
    {
      options.modules.system.tailscale = {
        enable = lib.mkEnableOption "Enable Tailscale";
        server = lib.mkEnableOption ''
          headless-server networking: Tailscale SSH, client subnet routing, and the
          base CLI tools a remote box needs. Intended for machines administered
          purely over the tailnet (e.g. an external flake's NixOS VM), not
          desktops. The firewall of such a box is not opened here: it is rendered
          from `tailnet.openPorts` (modules/system/tailnet.nix)'';
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
in
{
  flake.modules.nixos.tailscale = mkModule;
  flake.modules.darwin.tailscale = mkModule;
}
