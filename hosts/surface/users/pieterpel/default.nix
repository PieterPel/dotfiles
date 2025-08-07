{ inputs, ... }:
let
  gitCredentialPath = "/mnt/c/Users/ROB8135/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe";
  username = "pieterpel";
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
{

  homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;

    modules = [
      ../../../../profiles/user/wsl
      ../../../../modules/hm-standalone
      {
        inherit username;

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
