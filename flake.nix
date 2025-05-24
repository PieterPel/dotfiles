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

  outputs = { self, nixpkgs, home-manager, nixvim, stylix, spicetify-nix, nix-flatpak, ... }@inputs: 
  let 
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ 
          ./modules/core/configuration.nix 
          home-manager.nixosModules.default
          stylix.nixosModules.stylix
          spicetify-nix.nixosModules.spicetify
        ];
      };
    };

    homeConfigurations."nixos" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      # Specify your home configuration modules here 
      modules = [ 
          ./modules/home/home.nix
          # ./wsl.nix
      ];

      extraSpecialArgs = { inherit inputs; }; # Allows access to inputs in modules
    };
  };
}
