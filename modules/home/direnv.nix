{
  config,
  pkgs,
  inputs,
  ...
}:

{
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
