{
  inputs,
  ...
}:
{
  flake.modules.homeManager.flatpaks = { config, lib, ... }:
    let
      cfg = config.modules.package-management.flatpaks;
    in
    {
      imports = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      options.modules.package-management.flatpaks = {
        enable = lib.mkEnableOption "Enable flatpaks  configuration";
      };
      config = lib.mkIf cfg.enable {services.flatpak = {
        packages = [
          #"org.onlyoffice.desktopeditors"
        ];
      };
    };
  };
}
