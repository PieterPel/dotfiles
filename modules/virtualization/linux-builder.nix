{
  flake.modules.darwin.linux-builder = { config, lib, pkgs, ... }:
    let
      cfg = config.modules.virtualization.linux-builder;
    in
    {
      options.modules.virtualization.linux-builder = {
        enable = lib.mkEnableOption "Enable the native Linux builder VM";
      };

      config = lib.mkIf cfg.enable {
        # `darwin.linux-builder-vz` runs the build VM on Apple's
        # Virtualization.framework instead of QEMU. Two consequences worth
        # knowing before touching the settings below:
        #
        #   * It only works on Apple Silicon. The VZ backend has no Intel
        #     support, so this must stay off for `rebel-pieter` if that host
        #     ever turns out to be x86_64-darwin. Check with `uname -m`
        #     before enabling it on a new host.
        #   * Rosetta lets the guest execute x86_64 binaries, which is why
        #     `x86_64-linux` can be listed under `systems` even though the
        #     host is aarch64. That is the whole point of using -vz here:
        #     building x86_64-linux derivations (e.g. amd64 container
        #     images) would otherwise fall back to slow QEMU emulation.
        nix.linux-builder = {
          enable = true;
          package = pkgs.darwin.linux-builder-vz;

          # aarch64-linux is the native guest arch; x86_64-linux comes via
          # Rosetta. Dropping x86_64-linux here would silently make amd64
          # builds unavailable rather than slow.
          systems = [
            "aarch64-linux"
            "x86_64-linux"
          ];

          # Keep the guest store between restarts. The alternative wipes the
          # data disk on every start, which throws away every substitution the
          # VM has already downloaded. The trade-off is that `diskSize` below
          # is only honoured on a fresh qcow2: after changing it, delete
          # /var/lib/linux-builder/nixos.qcow2 so the VM is recreated
          # (nix-darwin#1200).
          ephemeral = false;

          # Should track `virtualisation.cores` in `config` below. Setting
          # only one of the two lets the scheduler and the VM disagree about
          # how much work can run at once.
          maxJobs = 6;

          config.virtualisation = {
            darwin-builder = {
              diskSize = 60 * 1024; # MiB, a maximum: the qcow2 is sparse
              memorySize = 8 * 1024; # MiB ceiling, not a reservation
            };
            cores = 6;
          };
        };
      };
    };
}
