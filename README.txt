NOTES:

* Dependencies:
chezmoi
xz-utils
nix

* Workflow:
install dependencies
chezmoi init --apply <your-dotfiles-repo>
nix run .#homeConfigurations.pieter.activationPackage


