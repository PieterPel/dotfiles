{ pkgs
, self
, ...
}:
let
  mkUser = import ../../../lib/mkUser.nix;
  username = "pieterpel";
in
{
  users.users.${username} = mkUser pkgs username;
  home-manager.users.${username} = {
    imports = builtins.attrValues self.homeModules ++ [
      ../../../profiles/user/laptop
    ];
  };
}
