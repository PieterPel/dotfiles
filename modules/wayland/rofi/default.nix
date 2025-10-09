{
  config,
  ...
}:
{
  flake.modules.homeManager.rofi = {
    imports = [
      config.flake.modules.homeManager."rofi-config-long"
      config.flake.modules.homeManager."rofi-config"
    ];
  };
}