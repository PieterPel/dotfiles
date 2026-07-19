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
      # Track the nixos-unstable branch to match our 26.11 nixpkgs: `main`
      # pins an older nixpkgs whose kernel lacks `kernel.buildDTBs`, which the
      # newer device-tree module now reads by default (nixos-raspberrypi #201).
      url = "github:nvmd/nixos-raspberrypi/nixos-unstable";
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
