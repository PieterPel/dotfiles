{ config, lib, ... }:

let
  cfg = config.modules.nixos.virtualization;
in
{
  options.modules.nixos.virtualization = {
    enable = lib.mkEnableOption "Enable virtualization module";
  };

  config = lib.mkIf cfg.enable {
    # Enable common container config files in /etc/containers
    boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ]; # Enable cgroups v2
    virtualisation.containers.enable = true;
    virtualisation = {
      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
