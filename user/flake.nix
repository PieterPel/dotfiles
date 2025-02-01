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
    
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixvim, ... } @ inputs:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
         inherit system;
	     config = { 
           allowUnfree = true;
           allowUnfreePredicate = _: true;
        };
      };
    in {
      homeConfigurations."nixos" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here 
        modules = [ 
            ./home.nix
	        nixvim.homeManagerModules.nixvim
	        ./packages/nixvim.nix
        ];
	
	    extraSpecialArgs = { inherit inputs; }; # Allows access to inputs in modules
      };
  };
}
