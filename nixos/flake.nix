{
  description = "A very basic flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixneovim.url = "github:nixneovim/nixneovim";
  };

  outputs = { self, nixpkgs, nixos-wsl }: {
     nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       modules = [
        ./configuration.nix
        nixos-wsl.nixosModules.wsl
       ];
     };
     
     # More neovim plugins using https://github.com/NixNeovim/NixNeovimPlugins
     nixpkgs.overlays = [
        nixneovim.overlays.default 
     ];
  };
}
