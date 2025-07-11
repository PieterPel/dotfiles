{
  pkgs,
  inputs,
  username,
  ...
}:
{
  # Here you can put stuff that is only needed if home-manager is used standalone
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
    polarity = "dark";
  };

  home.username = username;
  home.homeDirectory = "/home/${username}";
}
