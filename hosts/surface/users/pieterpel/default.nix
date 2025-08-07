{ config, inputs, ... }:
let
  gitCredentialPath = "/mnt/c/Users/ROB8135/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe";
  username = "pieterpel";
  hostname = "surface";
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
{

  flake.homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inherit inputs;
    };

    modules = [
      ../../../../profiles/user/wsl
      ../../../../modules/hm-standalone
      {
        inherit username;
        inherit hostname;

        programs.git = {
          extraConfig = {
            credential = {
              helper = gitCredentialPath;
            };
          };
        };
      }
    ];
  };
}
