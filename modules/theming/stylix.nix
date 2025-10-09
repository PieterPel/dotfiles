{
  inputs, 
  ...
}:
let
  polarity = "dark";
  image = ../../wallpapers/tux-teaching.jpg;
  base16Scheme = pkgs: "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
  systemModule = { lib, config, pkgs, ... }: {
    options.modules.core.stylix = {
      enable = lib.mkEnableOption "Enable stylix module";
    };
    config = lib.mkIf config.modules.core.stylix.enable {
      environment.systemPackages = with pkgs; [ base16-schemes ];
      stylix = {
        enable = true;
        base16Scheme = base16Scheme pkgs;
        inherit image polarity;
      };
    };
  };

  homeModule = { lib, config, pkgs, ... }: {
    options.modules.stylix = {
      enable = lib.mkEnableOption "Enable Stylix theming configuration.";
    };
    config = lib.mkIf config.modules.stylix.enable {
      packages = with pkgs; [ base16-schemes ];
      stylix = {
        inherit image polarity;
        enable = true;
        base16Scheme = base16Scheme pkgs;
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
        };
      };
    };
  };

in
{
  flake.modules.nixos.stylix = systemModule;
  flake.modules.darwin.stylix = systemModule;
  flake.modules.homeManager.stylix = homeModule;

  flake.modules.standaloneHomeManager.stylix = { pkgs, ... }: {
    stylix = {
      inherit polarity;
      base16Scheme = base16Scheme pkgs;
    };
  };
}
