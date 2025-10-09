{
  flake.modules.homeManager.flatpaks = { ... }:
    {
      config.services.flatpak = {
        packages = [
          #"org.onlyoffice.desktopeditors"
        ];
      };
    };
}
