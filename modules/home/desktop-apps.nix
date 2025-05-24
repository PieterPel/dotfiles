{ config, pkgs, inputs, ... }:

{
  imports = [
    ./kitty.nix
    ./hyprland
    ./vscodium.nix
    ./waybar.nix
    ./wlogout
    ./rofi
    ./spicetify.nix 
    ./flatpaks.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  home.packages = with pkgs; [
    # Screenshots
    grim
    slurp
    swappy

    # Photoshop
    gimp

    # Font
    montserrat

    # Browser
    brave
    chromium
  ];

  stylix = {
    enable = true;
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
    }; 
  };


}

