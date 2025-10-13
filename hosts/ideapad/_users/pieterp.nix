{ pkgs
, self
, ...
}:
let
  mkUser = import ../../../lib/mkUser.nix;
  username = "pieterp";
in
{
  users.users.${username} = mkUser pkgs username;
  home-manager.users.${username} = {
    imports = builtins.attrValues self.modules.homeManager;
    config = {
      modules.profiles.laptop.enable = true;
    };
  };
}
