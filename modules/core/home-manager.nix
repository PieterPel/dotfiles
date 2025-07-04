{
  inputs,
  host,
  username,
  profile,
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
      inherit profile;
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users = {
      ${username} = import ../home/home.nix;
    };
  };
}
