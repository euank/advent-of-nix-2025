{
  description = "Advent of code, 2025, solved with nix";

  inputs = { };

  outputs =
    { ... }:
    let
      lib = import ./lib.nix;
      dayDirs = lib.attrs.filter (name: _: lib.strings.hasPrefix "day" name) (builtins.readDir ./.);
    in
    {
      inherit lib;
    }
    // (builtins.mapAttrs (name: _: import ./${name} { inherit lib; }) dayDirs);
}
