{
  lib,
  config,
  ...
}:

{
  imports = [
    ./terminal-apps.nix
    ./desktop-apps.nix
  ];

  config = {

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "24.11"; # Please read the comment before changing.

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
  };
}
