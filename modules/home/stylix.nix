{ pkgs
, inputs
, config
, lib
, ...
}:

let
  cfg = config.modules.stylix;
in
{
  options.modules.stylix = {
    enable = lib.mkEnableOption "Enable Stylix theming configuration.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ base16-schemes ];

    stylix = {
      enable = true;

      # These colors were very dark by default which can make text on a dark background unreadable
      # override.base03 = "ffb9ff";
      override.base0F = "ff729a";

      opacity = {
        desktop = 0.5;
        terminal = 0.8;
      };

      cursor = {
        package = inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
        name = "BreezX-RosePine-Linux";
        size = 24;
      };

      targets = {
        vscode.profileNames = [ "pieterp" ];
        vscode.enable = false;
        nixvim.plugin = "base16-nvim";
        rofi.enable = true;
        tmux.enable = false;
        hyprlock.enable = false;
      };
    };
  };
}

