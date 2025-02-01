{
  description = "A very basic flake for NixOS for WSL";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
  };

  outputs = { self, nixpkgs, nixos-wsl } @inputs:
  {
     nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
       specialArgs = { inherit inputs; };

       system = "x86_64-linux";
       modules = [
        ./configuration.nix
        nixos-wsl.nixosModules.wsl
       ];
     };
  };
}
