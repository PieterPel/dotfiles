{
  config,
  pkgs,
  inputs,
  ...
}:

{
  config.services.flatpak = {
    packages = [
      #"org.onlyoffice.desktopeditors"
    ];
  };
}
