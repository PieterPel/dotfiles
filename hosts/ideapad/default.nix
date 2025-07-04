{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  services.fprintd = {
    enable = true;
  };

  powerManagement.enable = true;

}
