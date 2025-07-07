{
  profile,
  ...
}:
{
  imports = [
    # Make sure to import options.nix first
    ./options.nix
    ./home.nix
    ./profiles/${profile}.nix
  ];
}
