{
  description = "Advent of code, 2025, solved with nix";

  inputs = { };

  outputs =
    { ... }:
    let
      lib = import ./lib.nix;
      dayDirs = lib.filterAttrs (name: _: lib.hasPrefix "day" name) (builtins.readDir ./.);
    in
    {
      inherit lib;
    }
    // (builtins.mapAttrs (name: _: import ./${name} { inherit lib; }) dayDirs);
}
