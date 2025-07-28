{
  description = "A very basic flake for NixOS for WSL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    { self
    , nixpkgs
    , nixos-wsl
    , vscode-server
    ,
    }@inputs:
    {
      nixosConfigurations.nixos =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
          };
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };

          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            nixos-wsl.nixosModules.wsl
            vscode-server.nixosModules.default
          ];
        };
    };
}
