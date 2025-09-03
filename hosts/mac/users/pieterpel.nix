{ pkgs
, ...
}:
let
  mkUser = import ../../../lib/mkUser.nix;
  username = "pieterpel";
in
{
  users.users.${username} = mkUser pkgs username;
  home-manager.users.${username} = {
    imports = [
      ../../../modules/home
      ../../../profiles/user/laptop
    ];
  };
}
