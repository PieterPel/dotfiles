{ ...
}:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.kernel.sysctl = {
    # Force redis to work optimally
    "vm.overcommit_memory" = 1;
  };
}
