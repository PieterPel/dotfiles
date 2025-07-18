{
  pkgs,
  system-profile,
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

  };

  home.shellAliases = {
    # NixOS
    nos = "nh os switch ~/dotfiles#${system-profile}";
    noe = "nvim ~/dotfiles/";

    # Home-manager
    hms = "nh home switch ~/dotfiles/";

    # Devenv
    dev-init = "nix flake init --template github:cachix/devenv";

    # CLI dropins
    cat = "bat";

    # LazyGit
    lg = "lazygit";

    # eza
    ls = "eza --color=always --group-directories-first --icons";
    ll = "eza -la --icons --octal-permissions --group-directories-first";
    l = "eza -bGF --header --git --color=always --group-directories-first --icons";
    llm = "eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons";
    la = "eza --long --all --group --group-directories-first";
    lx = "eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons";
    lS = "eza -1 --color=always --group-directories-first --icons";
    lt = "eza --tree --level=2 --color=always --group-directories-first --icons";
    "l." = "eza -a | grep -E '^\\.'";
  };
}
