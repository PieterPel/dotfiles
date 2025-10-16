{
  lib,
  ...
}:
let
  defaultEnable = {
    enable = lib.mkDefault true;
  };

  nixosDefaults = {
    modules = {
      de.gnome = defaultEnable;
      gaming.steam = defaultEnable;
      gui.thunar = defaultEnable;
      home."home-manager" = defaultEnable;
      package-management.nix = defaultEnable;
      security.sops = defaultEnable;
      system = {
        boot = defaultEnable;
        configuration = defaultEnable;
        fonts = defaultEnable;
        internationalization = defaultEnable;
        networking = defaultEnable;
        printing = defaultEnable;
        sound = defaultEnable;
        updating = defaultEnable;
      };
      theming.stylix = defaultEnable;
      virtualization.virtualization = defaultEnable;
      wm.hyprland = defaultEnable;
    };
  };

  darwinDefaults = {
    modules = {
      home."home-manager" = defaultEnable;
      package-management = {
        homebrew = defaultEnable;
        nix = defaultEnable;
      };
      security.sops = defaultEnable;
      system = {
        configuration = defaultEnable;
        fonts = defaultEnable;
      };
      theming.stylix = defaultEnable;
      wm.aerospace = defaultEnable;
    };
  };

  homeManagerDefaults = {
    modules = {
      gui = {
        "desktop-apps" = defaultEnable;
        ghostty = defaultEnable;
        kitty = defaultEnable;
        spicetify = defaultEnable;
        vscodium = defaultEnable;
        zed = defaultEnable;
      };
      package-management.flatpaks = defaultEnable;
      programs.nixvim = defaultEnable;
      terminal = {
        ai = defaultEnable;
        direnv = defaultEnable;
        fish = defaultEnable;
        git = defaultEnable;
        nixvim = defaultEnable;
        starship = defaultEnable;
        tmux = defaultEnable;
        "terminal-apps" = defaultEnable;
      };
      theming.stylix = defaultEnable;
      wayland = {
        hyprlock = defaultEnable;
        rofi = defaultEnable;
        waybar = defaultEnable;
        wlogout = defaultEnable;
      };
      wm.hyprland = defaultEnable;
    };
  };

  mkFullProfileModule =
    defaults:
    { config, options, ... }:
    let
      cfg = config.modules.profiles.full;
      prunedDefaults =
        if defaults ? modules && defaults.modules ? wm && !(lib.hasAttrByPath [ "modules" "wm" ] options) then
          defaults
          // {
            modules = builtins.removeAttrs defaults.modules [ "wm" ];
          }
        else
          defaults;
    in
    {
      options.modules.profiles.full.enable = lib.mkEnableOption "Enable the full profile";
      config = lib.mkIf cfg.enable prunedDefaults;
    };
in
{
  flake.modules.nixos.full = mkFullProfileModule nixosDefaults;
  flake.modules.darwin.full = mkFullProfileModule darwinDefaults;
  flake.modules.homeManager.full = mkFullProfileModule homeManagerDefaults;
}
