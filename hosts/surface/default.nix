{ inputs, ... }:

let
  hostname = "surface";
  system = "x86_64-linux";
in
{
  imports = [
    (import ./users/pieterpel { inherit inputs system hostname; })
  ];
}
