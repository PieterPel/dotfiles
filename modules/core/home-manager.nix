{ pkgs
, inputs
, host
, username
, system-profile
, user-profile
, ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    home-manager # Not strictly needed, but now we can also use home-manager commands
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
