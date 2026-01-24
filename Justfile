set shell := ["zsh", "-cu"]

# Generate a local age key for sops-nix on macOS.
sops-age-keygen:
    mkdir -p ~/.config/sops/age
    age-keygen -o ~/.config/sops/age/keys.txt

# Run flake checks with local sops key paths available.
check:
    nix flake check --impure
