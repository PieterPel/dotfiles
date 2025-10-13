{
  flake.modules.nixos.printing = { config, lib, ... }:
    let
      cfg = config.modules.system.printing;
    in
    {
      options.modules.system.printing = {
        enable = lib.mkEnableOption "Enable printing module";
      };

      config = lib.mkIf cfg.enable {
        # Enable CUPS to print documents.
        services.printing.enable = true;
      };
    };
}
