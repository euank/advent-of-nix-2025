{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      lines = strings.lines input;
      points = map (xyz: let parts = map (ints.parse) (strings.split "," xyz); els = lists.elemAt parts; in { x = els 0; y = els 1; z = els 2; }) lines;
    in
    points;

    part1 =
    let
      p = parse input;
    in
    p;
in
{
  inherit part1;
}
