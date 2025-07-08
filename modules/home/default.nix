{
  user-profile,
  host,
  username,
  ...
}:

let
  potentialUserModulePath = ../hosts/${host}/users/${username}/default.nix;
  potentialUserModule =
    if builtins.pathExists (potentialUserModulePath) then potentialUserModulePath else { };

  potentialUserProfilePath = ./profiles/${user-profile}.nix; # TODO: change to directory?
  potentialUserProfile =
    if builtins.pathExists (potentialUserProfilePath) then potentialUserProfilePath else { };
in
{
  imports = [
    # Make sure to import options.nix first
    ./options.nix
    ./home.nix
    potentialUserModule
    potentialUserProfile
  ];
}
