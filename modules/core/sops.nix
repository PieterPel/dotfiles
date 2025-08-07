{ pkgs, ... }:

let
  wifiSecrets = ../../secrets/wifi.yaml;
in
{
  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  sops = {
    secrets = {
      "wifi/HomeNetwork/ssid" = {
        sopsFile = wifiSecrets;
      };
      "wifi/HomeNetwork/password" = {
        sopsFile = wifiSecrets;
      };
    };
  };
}
