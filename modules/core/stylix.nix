{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
    image = ../../wallpapers/tux-teaching.jpg;
    polarity = "dark";
  };
}
