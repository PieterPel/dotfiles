{ ... }:
let
  gitCredentialPath = "/mnt/c/Users/ROB8135/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe";
in
{
  programs.git = {
    extraConfig = {
      credential = {
        helper = gitCredentialPath;
      };
    };
  };
}
