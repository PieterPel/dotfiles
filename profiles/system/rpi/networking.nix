{ ... }:
let
  interface = "wlan0";
  SSID = builtins.readFile "/run/secrets/wifi/HomeNetwork/ssid";
  SSIDpassword = builtins.readFile "/run/secrets/wifi/HomeNetwork/password";
in
{
  networking = {
    wireless = {
      enable = true;
      networks."${SSID}".psk = SSIDpassword;
      interfaces = [ interface ];
    };
  };
}
