{ config, pkgs, inputs, ... }:

{

  imports = [
    ./packages
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

    # File management
    yazi

    # Utilities
    unzip

    # Terminal
    zoxide

    # Screenshots
    grim
    slurp
    swappy

    # Photoshop
    gimp
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

  programs.zoxide = {
	enable = true;
	options = [
	  "--cmd cd"
	];
  };

  stylix = {
    enable = true;
    targets.vscode.profileNames = [ "pieterp" ];
  };

  programs.btop.enable = true;
}
