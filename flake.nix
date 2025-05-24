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

  outputs = { self, nixpkgs, ... } @ inputs: 
  let 
    # Change these depending on your usecase
    system = "x86_64-linux";
    host = "nixos";
    username = "pieterp";
    profile = "laptop";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { 
          inherit inputs; 
          inherit host;
          inherit username;
          inherit profile;
        };

        modules = [ 
          ./modules/core/configuration.nix 
          inputs.home-manager.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.spicetify-nix.nixosModules.spicetify
        ];
      };
    };

    # TODO: could make NixOS WSL profile here, but I don't use that currently
    # TODO: make WSL profile for home-manager (for non-NixOS WSL) (maybe also for faster home-manager builds?)

    homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {

      inherit pkgs;

      modules = [ 
          ./modules/home/home.nix
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
