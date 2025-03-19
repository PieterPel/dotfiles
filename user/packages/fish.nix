{ config, pkgs, inputs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
        set fish_greeting # Disable greeting
    '';

    # Define plugins
    plugins = [
        { name = "tide"; src = pkgs.fishPlugins.tide.src; }
    ];

    # Define aliases
    shellAliases = {
      "hms" = "home-manager switch --flake ~/dotfiles/user/#nixos";
      "hme" = "nvim ~/dotfiles/user/home.nix";
      "hmf" = "nvim ~/dotfiles/user/flake.nix";
      "nos" = "sudo nixos-rebuild switch --flake ~/dotfiles/nixos#nixos";
      "noe" = "sudo nvim ~/dotfiles/nixos/configuration.nix";
      "nof" = "sudo nvim ~/dotfiles/nixos/flake.nix";
    };

  };
}
