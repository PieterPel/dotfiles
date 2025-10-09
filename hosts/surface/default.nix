{ inputs, ... }:

let
  hostname = "surface";
  system = "x86_64-linux";
in
{
  imports = [
    (import ./_users/pieterpel { inherit inputs system hostname; })
  ];
}
