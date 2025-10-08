{ config, lib, ... }:
{
  flake.homeModules.flatpaks = { ... }:
    {
      config.services.flatpak = {
        packages = [
          #"org.onlyoffice.desktopeditors"
        ];
      };
    };
}
