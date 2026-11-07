{ inputs, self, ... }:
{
  perSystem = { pkgs, system, ... }:
    let
      lib = inputs.nixpkgs.lib;
      # Evaluate Linux modules on Darwin too; the check itself builds locally.
      linuxSystem = if pkgs.stdenv.hostPlatform.isLinux then system else "x86_64-linux";
      evaluate = settings: (lib.nixosSystem {
        system = linuxSystem;
        modules = [
          self.modules.nixos.vm-baseline
          self.modules.nixos.vm-disk
          { modules.system.vmBaseline = settings; }
        ];
      }).config;
      swapSettings = cfg: map (swap: { inherit (swap) device size; }) cfg.swapDevices;
      disabled = evaluate { };
      defaults = evaluate { enable = true; hostname = "baseline-test"; };
      custom = evaluate {
        enable = true;
        hostname = "custom-vm";
        rootDisk = "/dev/vda";
        dataDiskLabel = "vm-data";
        dataMount = "/srv/data";
        swapSize = 2048;
        timeZone = "UTC";
        stateVersion = "25.05";
      };
    in
    {
      checks.vm-baseline =
        assert !disabled.nix.gc.automatic;
        assert disabled.swapDevices == [ ];
        assert !(disabled.fileSystems ? "/mnt/data");
        assert defaults.networking.hostName == "baseline-test";
        assert defaults.networking.useNetworkd;
        assert defaults.boot.loader.grub.enable;
        assert lib.elem "virtio_blk" defaults.boot.initrd.availableKernelModules;
        assert defaults.fileSystems."/".fsType == "ext4";
        assert defaults.fileSystems."/mnt/data".device == "/dev/disk/by-label/data";
        assert defaults.fileSystems."/mnt/data".options == [ "defaults" "nofail" ];
        assert swapSettings defaults == [{ device = "/mnt/data/swapfile"; size = 4096; }];
        assert defaults.time.timeZone == "Europe/Amsterdam";
        assert defaults.system.stateVersion == "25.05";
        assert defaults.nix.gc.automatic;
        assert defaults.nix.settings.min-free == 5 * 1024 * 1024 * 1024;
        assert defaults.nix.settings.max-free == 15 * 1024 * 1024 * 1024;
        assert custom.networking.hostName == "custom-vm";
        assert custom.disko.devices.disk.main.device == "/dev/vda";
        assert lib.elem "/dev/vda" custom.boot.loader.grub.devices;
        assert custom.fileSystems."/srv/data".device == "/dev/disk/by-label/vm-data";
        assert swapSettings custom == [{ device = "/srv/data/swapfile"; size = 2048; }];
        assert custom.time.timeZone == "UTC";
        pkgs.runCommand "vm-baseline-check" { } "touch $out";
    };
}
