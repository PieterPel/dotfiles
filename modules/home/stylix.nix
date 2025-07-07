{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.packages = with pkgs; [ base16-schemes ];

  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
    polarity = "dark";

    opacity = {
      desktop = 0.5;
      terminal = 0.8;
    };

    cursor = {
      package = inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
      name = "BreezX-RosePine-Linux";
      size = 24;
    };

    targets = {
      vscode.profileNames = [ "pieterp" ];
      vscode.enable = false;
      nixvim.plugin = "base16-nvim";
      rofi.enable = true;
    };
  };
}
