{ pkgs
, ...
}:
{
  imports = [
    ./options.nix
    ./aliases.nix
    ./direnv.nix
    ./spicetify.nix
    ./starship.nix
    ./tmux.nix
    ./zed.nix
    ./nixvim
  ];

  # These are core packages I always want to have installed
  packages = with pkgs; [
    vim
    git
    base16-schemes
    fastfetch
    comma
  ];

}
