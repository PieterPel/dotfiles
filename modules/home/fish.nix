{
  config,
  pkgs,
  inputs,
  ...
}:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';

    # Define plugins
    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];

    # Define aliases
    shellAliases = {
      # NixOS
      "nos" = "sudo nixos-rebuild switch --flake ~/dotfiles#laptop";
      "noe" = "nvim ~/dotfiles/";

      # Devenv
      "dev-init" = "nix flake init --template github:cachix/devenv";

      # CLI dropins
      "cat" = "bat";
    };

  };
}
