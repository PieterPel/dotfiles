{ inputs, ... }:
let
  mkSopsModule =
    modules:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.security.sops;
    in
    {
      options.modules.security.sops = {
        enable = lib.mkEnableOption "Enable sops module";
        ageKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Age key file for sops-nix.";
        };
        ageSshKeyPaths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "SSH key paths for age (sops-nix).";
        };
        gnupgHome = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "GnuPG home for sops-nix.";
        };
        gnupgSshKeyPaths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "GnuPG SSH key paths for sops-nix.";
        };
        defaultSopsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Default sops file for sops-nix.";
        };
        validateSopsFiles = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Validate sops files at evaluation time.";
        };
      };

      imports = [
        inputs.sops-nix.${modules}.default
      ];

      config = lib.mkIf cfg.enable {
        packages = with pkgs; [
          sops
          age
          ssh-to-age
        ];

        sops =
          {
            secrets = { };
          }
          // lib.optionalAttrs (cfg.ageKeyFile != null) {
            age.keyFile = cfg.ageKeyFile;
          }
          // lib.optionalAttrs (cfg.ageSshKeyPaths != [ ]) {
            age.sshKeyPaths = cfg.ageSshKeyPaths;
          }
          // lib.optionalAttrs (cfg.gnupgHome != null) {
            gnupg.home = cfg.gnupgHome;
          }
          // lib.optionalAttrs (cfg.gnupgSshKeyPaths != [ ]) {
            gnupg.sshKeyPaths = cfg.gnupgSshKeyPaths;
          }
          // lib.optionalAttrs (cfg.defaultSopsFile != null) {
            inherit (cfg) defaultSopsFile;
          }
          // {
            inherit (cfg) validateSopsFiles;
          };
      };
    };

  mkHmSopsModule =
    { config, lib, pkgs, ... }:
    let
      cfg = config.modules.security.sops;
      defaultAgeKeyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    in
    {
      options.modules.security.sops = {
        enable = lib.mkEnableOption "Enable sops module";
        ageKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Age key file for sops-nix.";
        };
        ageSshKeyPaths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "SSH key paths for age (sops-nix).";
        };
        gnupgHome = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "GnuPG home for sops-nix.";
        };
        gnupgSshKeyPaths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "GnuPG SSH key paths for sops-nix.";
        };
        defaultSopsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Default sops file for sops-nix.";
        };
        validateSopsFiles = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Validate sops files at evaluation time.";
        };
      };

      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          sops
          age
          ssh-to-age
        ];

        # Ensure launchd agents can find system tools like getconf on macOS.
        home.sessionPath = lib.mkAfter [
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
        ];

        sops =
          { }
          // {
            environment = {
              PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
            };
          }
          // {
            age.keyFile = lib.mkDefault (if cfg.ageKeyFile != null then cfg.ageKeyFile else defaultAgeKeyFile);
          }
          // {
            # Avoid %r so sops-nix doesn't need getconf on macOS launchd.
            defaultSecretsMountPoint = lib.mkDefault "${config.xdg.stateHome}/sops-nix/secrets.d";
          }
          // lib.optionalAttrs (cfg.ageSshKeyPaths != [ ]) {
            age.sshKeyPaths = cfg.ageSshKeyPaths;
          }
          // lib.optionalAttrs (cfg.gnupgHome != null) {
            gnupg.home = cfg.gnupgHome;
          }
          // lib.optionalAttrs (cfg.gnupgSshKeyPaths != [ ]) {
            gnupg.sshKeyPaths = cfg.gnupgSshKeyPaths;
          }
          // lib.optionalAttrs (cfg.defaultSopsFile != null) {
            inherit (cfg) defaultSopsFile;
          }
          // {
            inherit (cfg) validateSopsFiles;
          };
      };
    };
in
{
  flake.modules = {
    nixos.sops = mkSopsModule "nixosModules";
    darwin.sops = mkSopsModule "darwinModules";
    homeManager.sops = mkHmSopsModule;
  };
}
