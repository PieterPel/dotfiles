{
  description = "My standard terminal setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: {
    # Expose a default package
    defaultPackage = {
      "x86_64-linux" = let
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
      in pkgs.buildEnv {
        name = "my-packages";
        paths = with pkgs; [
          # Version control
          git
          lazygit
          chezmoi

          # Languages              
          cargo  # Rust
          uv     # Python
          
          # Shell
          fish
          oh-my-fish

          # Developing
          neovim
          tmux
          helix

          # Performance
          btop

          # Utilities
          unzip
        ];
      };
    };

    # Optional: Expose packages explicitly for clarity
    packages = {
      "x86_64-linux" = self.defaultPackage."x86_64-linux";
    };
  };
}

