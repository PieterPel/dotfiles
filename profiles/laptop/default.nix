
{host, inputs, ...}: {
  imports = [
    ../../hosts/${host}/default.nix
    inputs.stylix.nixosModules.stylix
    inputs.spicetify-nix.nixosModules.spicetify
  ];
}
