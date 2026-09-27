{
  flake.modules.nixos.ssh =
    { config, lib, ... }:
    let
      cfg = config.modules.system.ssh;
    in
    {
      options.modules.system.ssh = {
        enable = lib.mkEnableOption "OpenSSH, key-only";

        rootKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Public keys allowed to log in as root.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "prohibit-password";
          };
        };

        users.users.root.openssh.authorizedKeys.keys = cfg.rootKeys;
      };
    };
}
