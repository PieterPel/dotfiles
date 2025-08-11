{ config, lib, ... }:

let
  cfg = config.modules.nixos.printing;
in
{
  options.modules.nixos.printing = {
    enable = lib.mkEnableOption "Enable printing module";
  };

  config = lib.mkIf cfg.enable {
    # Enable CUPS to print documents.
    services.printing.enable = true;
  };
}
