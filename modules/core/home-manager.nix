{
  inputs,
  host,
  username,
  system-profile,
  user-profile,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.default
  ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit host;
      inherit username;
      inherit system-profile;
      inherit user-profile;
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users = {
      ${username} = import ../home/default.nix;
    };

  };
}
