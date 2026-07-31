{
  description = "Dendritic flake configuration for NixOS, nix-darwin, and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprland/hyprlang";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-raspberrypi = {
      # Track `develop`, pinned to a commit matching a *successful* cachix
      # push (github actions run 2026-07-26). `nixos-unstable` looks like the
      # obviously-correct branch name but nixos-raspberrypi's own CI
      # (.github/workflows/cachix.yaml) only ever builds+pushes `develop` --
      # every cachix push run that's targeted `nixos-unstable` is entirely
      # absent from their Actions history. Building against `nixos-unstable`
      # meant every package that isn't independently cached elsewhere
      # (confirmed via `nix why-depends`: libcamera_rpi, then transitively
      # pipewire/gtk4 once that got patched) had to compile from source on
      # the Pi itself -- the whole point of this flake is to avoid that.
      # `develop` pins nixos-26.05 internally (vs. nixos-unstable's rolling
      # pin) -- newer than the nixos-25.11 that caused the original
      # kernel.buildDTBs breakage on `main`, so that issue shouldn't recur.
      url = "github:nvmd/nixos-raspberrypi/7a988e466a9a98196bf1a85d0d594bcc4aa2b82d";
      # WARNING: do not follow nixpkgs here!
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-parts
    , import-tree
    , ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        (import-tree ./modules)
        (import-tree ./hosts)
        (import-tree ./flake)
      ];
    };

}
