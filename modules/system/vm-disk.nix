{
  flake.modules.nixos.vm-disk =
    { config, lib, inputs, ... }:
    let
      cfg = config.modules.system.vmBaseline;
    in
    {
      # The layout is only meaningful with disko's own module loaded, so this
      # one carries it: a host that imports the disk definition gets the tool
      # that applies it.
      imports = [ inputs.disko.nixosModules.disko ];

      config = lib.mkIf cfg.enable {
        disko.devices.disk.main = {
          type = "disk";
          device = cfg.rootDisk;
          content = {
            type = "gpt";
            partitions = {
              bios = {
                priority = 1;
                start = "1MiB";
                end = "8MiB";
                type = "EF02";
              };

              root = {
                priority = 2;
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
}
