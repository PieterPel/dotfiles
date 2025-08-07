{ inputs
, config
, ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.default
  ];

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
