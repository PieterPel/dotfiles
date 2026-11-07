{
  flake.modules.nixos.vm-baseline =
    { config, lib, ... }:
    let
      cfg = config.modules.system.vmBaseline;
    in
    {
      options.modules.system.vmBaseline = {
        enable = lib.mkEnableOption "the boot and disk baseline of a Hetzner Cloud VM";

        hostname = lib.mkOption {
          type = lib.types.str;
          description = "Host name, as the tailnet sees it.";
        };

        rootDisk = lib.mkOption {
          type = lib.types.str;
          default = "/dev/sda";
          description = "Disk the root partition is installed on.";
        };

        dataDiskLabel = lib.mkOption {
          type = lib.types.str;
          default = "data";
          description = "Filesystem label of the second, larger disk.";
        };

        dataMount = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/data";
          description = "Where the second disk is mounted.";
        };

        swapSize = lib.mkOption {
          type = lib.types.int;
          default = 4096;
          description = "Swap file size in MiB, on the data disk.";
        };

        timeZone = lib.mkOption {
          type = lib.types.str;
          default = "Europe/Amsterdam";
        };

        stateVersion = lib.mkOption {
          type = lib.types.str;
          default = "25.05";
          description = "NixOS state version — do not change on a running machine.";
        };
      };

      config = lib.mkIf cfg.enable {
        # Hetzner Cloud VMs are QEMU: without these in the initrd the kernel
        # cannot find the root disk or bring up networking.
        boot.initrd.availableKernelModules = [
          "virtio_pci"
          "virtio_blk"
          "virtio_scsi"
          "virtio_net"
          "ahci"
          "sd_mod"
        ];

        boot.loader.grub.enable = true;

        networking.hostName = cfg.hostname;
        networking.useNetworkd = true;

        time.timeZone = cfg.timeZone;
        system.stateVersion = cfg.stateVersion;

        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        # Weekly GC alone is not reactive enough — two deploys in one day can
        # still fill the root disk between runs. Let the daemon collect
        # mid-build whenever free space drops below min-free.
        nix.settings = {
          min-free = 5 * 1024 * 1024 * 1024; # 5 GiB
          max-free = 15 * 1024 * 1024 * 1024; # 15 GiB
        };

        fileSystems.${cfg.dataMount} = {
          device = "/dev/disk/by-label/${cfg.dataDiskLabel}";
          fsType = "ext4";
          options = [
            "defaults"
            "nofail"
          ];
        };

        # The root disk runs near full; the data disk has room for a swap file,
        # and without one a bursty build gets OOM-killed once the services'
        # memory eats the headroom.
        swapDevices = [
          {
            device = "${cfg.dataMount}/swapfile";
            size = cfg.swapSize;
          }
        ];
      };
    };
}
