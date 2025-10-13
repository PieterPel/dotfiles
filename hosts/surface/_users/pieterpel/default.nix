{ inputs
, system
, hostname
, ...
}:
let
  gitCredentialPath = "/mnt/c/Users/ROB8135/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe";
  username = "pieterpel";
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
      ../../../../modules/hm-standalone
      {
        modules.profiles.wsl.enable = true;
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
