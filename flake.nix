{
  description = "Flake that I can use both for NixOS and home-manager standalone";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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

    stylix.url = "github:danth/stylix";

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprland/hyprlang";
    };

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      # You can change settings per system in flake-settings.nix
      settings = import ./flake-settings.nix;
      inherit (settings)
        system
        host
        username
        profile
        ;

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      potentialUserModulePath = ./hosts/${host}/users/${username}/default.nix;
      potentialUserModule =
        if builtins.pathExists (potentialUserModulePath) then potentialUserModulePath else { };
    in
    {
      # This flake provides output for sudo nixos-rebuild
      nixosConfigurations = {
        ${profile} = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit host;
            inherit username;
            inherit profile;
          };

          modules = [
            ./modules/core/configuration.nix
            ./profiles/${profile}/default.nix
            ./hosts/${host}/default.nix
            potentialUserModule
          ];
        };
      };

      # And for home-manager switch
      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {

        inherit pkgs;

        modules = [
          ./modules/home/default.nix
          potentialUserModule
          {
            # NOTE: if there come more discrepencies between nixos and home-manager standalone,
            # make seperate module
            home.username = username;
            home.homeDirectory = "/home/${username}";
          }
        ];

        extraSpecialArgs = {
          # Allows access to inputs in modules
          inherit inputs;
          inherit host;
          inherit username;
          inherit profile;
        };
      };
    };
}
