{ config, pkgs, inputs, ... }:
{
  services.fprintd = {
    enable = true;
  };
}
