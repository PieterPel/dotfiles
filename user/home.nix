{ config, pkgs, inputs, ... }:

{

  imports = [
    ./packages/default.nix
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.
  
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # Version control
    git
    lazygit

    # Languages
    python3
    cargo
    gcc
    nodejs_23

    # shell
    fish
    oh-my-fish

    # Developing
    tmux
    helix
    devenv

    # Performance
    btop

    # File management
    yazi

    # Utilities
    unzip

    # Terminal
    zoxide
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    # Bash

    # tmux
      
    };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/pieterpel/etc/profile.d/hm-session-vars.sh
  #
  
    #Example, but I switched to managing plugins in nix/neovim.nix
    #xdg.configFile = {
    #  "nvim" = {
    #          source = config.lib.file.mkOutOfStoreSymlink ./dotconfig/nvim;        
    #      };
    #};
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Enable home-manager to govern programs..
  programs.home-manager = {
        enable = true;
  };
  
  # Enable and configure others
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
    
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.prefix-highlight
      tmuxPlugins.power-theme
      tmuxPlugins.continuum
    ];
    extraConfig = ''
      set -gu default-command
      set -g default-shell "$SHELL"
      set -g mouse on
    '';
  };

  programs.zoxide = {
	enable = true;
	options = [
	  "--cmd cd"
	];
  };

}
