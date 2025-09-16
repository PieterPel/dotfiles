{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.modules.programs.sketchybar;
  sketchybar = lib.getExe pkgs.sketchybar;
  aerospace = lib.getExe pkgs.aerospace;
in
{
  options.modules.programs.sketchybar = {
    enable = lib.mkEnableOption "Enable sketchybar configuration.";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.file.".config/sketchybar/sketchybarrc".text = ''
      ${sketchybar} --add event aerospace_workspace_change

      for sid in $(${aerospace} list-workspaces --all); do
          ${sketchybar} --add item space.$sid left \
              --subscribe space.$sid aerospace_workspace_change \
              --set space.$sid \
              background.color=0x44ffffff \
              background.corner_radius=5 \
              background.height=20 \
              background.drawing=off \
              label="$sid" \
              click_script="aerospace workspace $sid" \
              script="$CONFIG_DIR/plugins/aerospace.sh $sid"
      done
    '';

    home.file.".config/sketchybar/plugins/aerospace.sh".text = ''
      #!/usr/bin/env bash

      if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
          ${sketchybar} --set $NAME background.drawing=on
      else
          ${sketchybar} --set $NAME background.drawing=off
      fi
    '';

    home.activation.makeSketchyPluginsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      chmod +x $HOME/.config/sketchybar/plugins/aerospace.sh
    '';
  };
}
