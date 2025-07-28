{
  description = "Flake that I can use both for NixOS and home-manager standalone";

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

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
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
        system-profile
        user-profile
        ;

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # This flake provides output for `sudo nixos-rebuild switch`
      nixosConfigurations = {
        ${system-profile} = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit host;
            inherit username;
            inherit system-profile;
            inherit user-profile;
          };

          modules = [
            ./modules/core/configuration.nix
            ./modules/nixos/configuration.nix
            ./profiles/system/${system-profile}/default.nix
            ./hosts/${host}/default.nix
          ];
        };
      };

      # And for `sudo darwin-rebuild switch`
      darwinConfigurations.${host} = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs;
          inherit host;
          inherit username;
          inherit system-profile;
          inherit user-profile;
        };

        modules = [
          ./modules/core/configuration.nix
          ./modules/darwin/configuration.nix
          ./profiles/system/${system-profile}/default.nix
          ./hosts/${host}/default.nix
        ];
      };

      # And for `home-manager switch`
      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {

        inherit pkgs;

        extraSpecialArgs = {
          inherit inputs;
          inherit host;
          inherit username;
          inherit system-profile;
          inherit user-profile;
        };

        modules = [
          ./modules/home/default.nix
          ./modules/home/standalone.nix
        ];
      };

      # Define checks
      checks = forAllSystems (system: {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
          };
        };
      });

      # Define dev shells
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });
    };
}
