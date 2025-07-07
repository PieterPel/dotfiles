{ config, pkgs, ... }:
{
  home.packages =
    with pkgs;
    (
      if config.enableDesktopApps then
        [
          # There is a home-manager module but it sucks
          zed-editor

          # These are to get LSPs workihg nicely
          rust-analyzer
          ruff
          nil
          basedpyright
        ]
      else
        [ ]
    );

}
