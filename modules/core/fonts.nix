
{pkgs, ...}:

{

  environment.systemPackages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  fonts = {
    fontconfig = {
      antialias = true;
      
      # Fixes antialiasing blur
      hinting = {
        enable = true;
        style = "full"; # no difference
        autohint = true; # no difference
      };

      subpixel = {
        # Makes it bolder
        rgba = "rgb";
        lcdfilter = "default"; # no difference
      };
    };
  };
}
