{ ... }:

let
  interface = "wlan0";
  SSIDpasswordFile = "/run/secrets/wifi/HomeNetwork/password";
in
{
  networking = {
    wireless = {
      enable = true;
      interfaces = [ interface ];
      networks = {
        "RVers zijn koeien" = {
          pskFile = SSIDpasswordFile;
        };
      };
    };
  };
}
