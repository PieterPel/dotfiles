{ config, pkgs, inputs, ... }:

{
  config.services.flatpak = {
    enable = true;
    packages = [
      "flathub:app/org.onlyoffice.desktopeditors//stable"
    ];

    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
  };
}
