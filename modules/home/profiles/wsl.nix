{
  inputs,
  pkgs,
}:
{
  # TODO: this needs to be picked up on standalone home-manager -> time for seperate module
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
    polarity = "dark";
  };
}
