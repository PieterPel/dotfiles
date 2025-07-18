{
  pkgs,
  host,
  username,
  ...
}:

{
  imports = [
    ./spicetify.nix
    ./home-manager.nix
    ./stylix.nix
    ./fonts.nix
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://cache.nixos.org/"
      "https://devenv.cachix.org"
    ];

    trusted-public-keys = [
      "devenv.cachix.org-1:LsUwPwJv9iW7NLhFhJPDGFkqpT7LhNkpIws88soZV/M="
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  # Enable fish so it can be used as the default shell.
  programs.fish.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    base16-schemes
    neofetch
    home-manager # So we can also rebuild home-manager as flake itself
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Automatic cleanup
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older than 10d";
  };
  nix.settings.auto-optimise-store = true;

  # Automatic updating
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };
}
