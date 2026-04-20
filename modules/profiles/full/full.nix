{ lib
, inputs
, ...
}:
let
  defaultEnable = {
    enable = lib.mkDefault true;
  };
  defaultDisable = {
    enable = lib.mkDefault false;
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
      virtualization.docker-mcp = defaultEnable;
    };
  };

  homeManagerDefaults = {
    modules = {
      gui = {
        desktopApps = defaultEnable;
        ghostty = defaultEnable;
        kitty = defaultEnable;
        spicetify = defaultDisable; # Hash mismatch (22-12-25)
        vscodium = defaultEnable;
        zed = defaultDisable; # Something broken (22-12-25)
      };
      package-management.flatpaks = defaultEnable;
      terminal = {
        ai = defaultEnable;
        atuin = defaultEnable;
        direnv = defaultEnable;
        fish = defaultEnable;
        git = defaultEnable;
        nixvim = defaultEnable;
        starship = defaultEnable;
        tmux = defaultEnable;
        terminalApps = defaultEnable;
        yazi = defaultEnable;
        sesh = defaultEnable;
        zoxide = defaultEnable;
        gh-dash = defaultEnable;
        lazygit = defaultEnable;
        jjui = defaultEnable;
        jujutsu = defaultEnable;
        delta = defaultEnable;
      };
      theming.stylix = defaultEnable;
      security.sops = defaultEnable;
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
    in
    {
      options.modules.profiles.full.enable = lib.mkEnableOption "Enable the full profile";
      config = lib.mkIf cfg.enable defaults;
    };
in
{
  flake.modules = {
    nixos.full = mkFullProfileModule nixosDefaults;
    darwin.full = mkFullProfileModule darwinDefaults;
    homeManager.full = mkFullProfileModule homeManagerDefaults;
  };
}
