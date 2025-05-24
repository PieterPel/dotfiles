{ config, pkgs, inputs, ... }:
{
  services.fprintd = {
    enable = true;
  };

  powerManagement.enable = true;
  services.tlp.enable = true;
}
