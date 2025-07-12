{
  pkgs,
  system-profile,
  ...
}:

{
  # Enable more shells than aliases also work for them
  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.nushell.enable = true;

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

  };

  home.shellAliases = {
    # NixOS
    nos = "sudo nh os switch ~/dotfiles#${system-profile}";
    noe = "nvim ~/dotfiles/";

    # Home-manager
    hms = "nh home switch ~/dotfiles/";

    # Devenv
    dev-init = "nix flake init --template github:cachix/devenv";

    # CLI dropins
    cat = "bat";

    # LazyGit
    lg = "lazygit";
  };
}
