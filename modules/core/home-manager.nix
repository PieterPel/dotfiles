{ inputs
, config
, ...
}:
{
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    # NOTE: Set the correct hostname for all users
    sharedModules = [
      {
        hostname = config.hostname;
      }
    ];
  };
}
