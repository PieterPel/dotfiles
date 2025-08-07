{ pkgs }:

username: {
  isNormalUser = true;
  description = username;
  extraGroups = [
    "networkmanager"
    "wheel"
    "input"
  ];
  shell = pkgs.fish;
}
