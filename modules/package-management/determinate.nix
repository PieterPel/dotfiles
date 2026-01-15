{ inputs, ... }:
{
  flake.modules.darwin.determinate =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.package-management.determinate;
      jq = lib.getExe pkgs.jq;
    in
    {
      imports = [
        inputs.determinate.darwinModules.default
      ];
      options.modules.package-management.determinate = {
        enable = lib.mkEnableOption "Enable determinate-nix configuration";
      };
      config = lib.mkIf cfg.enable {
        nix.enable = lib.mkForce false;
        modules.package-management.nix.enable = lib.mkForce false;
        #determinate-nix.customSettings = {};

        # Define the function in nix-darwin's fish module
        programs.fish.functions.nix-sync = ''
          # Get the revision from the local nixpkgs registry entry
          set -l rev (nix flake metadata nixpkgs --json | ${jq} -r '.resolved.rev')

          if test -z "$rev"
            set_color red; echo "❌ Could not find a nixpkgs revision in your registry."; set_color normal
            return 1
          end

          echo (set_color blue)"🔄 Syncing project to system revision: "(set_color yellow)"$rev"(set_color normal)

          # Update the lockfile to match your system's exact commit
          nix flake update --override-input nixpkgs "github:NixOS/nixpkgs/$rev"

          set_color green; echo "✅ Done!"; set_color normal
        '';
      };
    };
}
