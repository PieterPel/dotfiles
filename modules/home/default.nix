{ user-profile
, host
, username
, ...
}:

let
  potentialUserModulePath = ../../hosts/${host}/users/${username}/default.nix;
  potentialUserModule =
    if builtins.pathExists (potentialUserModulePath) then potentialUserModulePath else { };

  potentialUserProfilePath = ../../profiles/user/${user-profile}/default.nix;
  potentialUserProfile =
    if builtins.pathExists (potentialUserProfilePath) then potentialUserProfilePath else { };
in
{
  imports = [
    ./options.nix
    ./home.nix
    potentialUserModule
    potentialUserProfile
  ];
}
