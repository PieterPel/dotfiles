let
  mkModule =
    { config, lib, ... }:
    {
      options.modules.system.tailscale = {
        enable = lib.mkEnableOption "Enable Tailscale";
      };

      config = lib.mkIf config.modules.system.tailscale.enable {
        services.tailscale.enable = true;
      };
    };
in
{
  flake.modules.nixos.tailscale = mkModule;
  flake.modules.darwin.tailscale = mkModule;
}
