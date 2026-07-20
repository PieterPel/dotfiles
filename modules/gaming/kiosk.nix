{
  # Shared cage-based kiosk. Owns the Wayland compositor (cage) and the one-time
  # display-mode force (wlr-randr), then launches whatever frontend sets
  # `program`. Decoupled from the frontend so the mode is applied exactly once
  # regardless of which frontend is active — enabling a different one no
  # longer shuffles the wlr-randr logic around.
  flake.modules.nixos.kiosk =
    {
      config,
      lib,
      pkgs,
      self,
      ...
    }:
    let
      cfg = config.modules.gaming.kiosk;

      pkgsStock = self.lib.mkStockPkgs pkgs.stdenv.hostPlatform.system;

      # Force the mode via wlr-randr (talks to cage's wlr-output-management), then
      # exec the frontend. Runs inside the cage session, so the socket exists.
      launcher = pkgs.writeShellScript "kiosk-launcher" ''
        ${lib.optionalString (
          cfg.mode != null
        ) "${lib.getExe pkgsStock.wlr-randr} --output ${cfg.output} --mode ${cfg.mode} || true"}
        exec ${cfg.program}
      '';
    in
    {
      options.modules.gaming.kiosk = {
        enable = lib.mkEnableOption "cage Wayland kiosk compositor";

        user = lib.mkOption {
          type = lib.types.str;
          default = "guest";
          description = "User the kiosk (cage) session runs as.";
        };

        output = lib.mkOption {
          type = lib.types.str;
          default = "HDMI-A-1";
          description = "wlr-randr output name that `mode` is applied to.";
        };

        mode = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "1920x1080@60";
          description = ''
            If set, force this wlr-randr mode on `output` before launching the
            frontend. wlroots otherwise picks the display's preferred mode (often
            4K on a TV), which a Pi 400 can't drive smoothly and whose refresh rate
            throws off the frontend's frame pacing.
          '';
        };

        program = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.package lib.types.str);
          default = null;
          description = ''
            Executable the kiosk launches fullscreen — a frontend such as RetroArch
            or Pegasus. Frontend modules set this; Pegasus overrides RetroArch's
            mkDefault when it is enabled.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        # GPU access for the frontend's GL/GLES cores (v3d on the Pi).
        hardware.graphics.enable = true;

        assertions = [
          {
            assertion = cfg.program != null;
            message = "modules.gaming.kiosk.enable is set but no frontend set modules.gaming.kiosk.program (enable retroarch or pegasus).";
          }
        ];

        services.cage = {
          enable = true;
          user = cfg.user;
          package = pkgsStock.cage; # stock cage/wlroots -> fetched, not ARM-rebuilt
          program = launcher;
        };
      };
    };
}
