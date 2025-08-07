{ pkgs
, ...
}:
{

  environment.systemPackages = with pkgs; [
    base16-schemes
  ];

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
    image = ../../wallpapers/tux-teaching.jpg;
    polarity = "dark";
  };
}
