{ inputs
, config
, ...
}:
{
  home-manager = {
    hostname = config.hostname;
    extraSpecialArgs = {
      inherit inputs;
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };
}
