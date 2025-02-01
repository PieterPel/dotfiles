{
  description = "Home Manager configuration of pieterpel";

  inputs = {
    # Specify sources
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Follow same version
    };
    
    nixneovim = {
      url = "github:nixneovim/nixneovim";
    };
  };

  outputs = { nixpkgs, home-manager, nixneovim, ... } @ inputs:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
         inherit system;
	 overlays = [ nixneovim.overlays.default ];
	 config = { };
      };
    in {
      homeConfigurations."nixos" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here 
        modules = [ 
	    nixneovim.nixosModules.default
            ./home.nix
            ./nix/nixneovim.nix
        ];
	
	extraSpecialArgs = { inherit inputs; }; # Allows access to inputs in modules
      };
  };
}
