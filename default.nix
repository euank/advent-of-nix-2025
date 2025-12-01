let
  lib = import ./lib.nix;
in
{
  day01 = import ./day01 { inherit lib; };
}
