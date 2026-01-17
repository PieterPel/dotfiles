{ pkgs
, ...
}:
let
  mkUser = import ../../../lib/mkUser.nix;
  username = "guest";
in
{
  users.users.${username} = mkUser pkgs username;
  # users.users.${username}.password = 
}
