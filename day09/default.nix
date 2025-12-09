{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      lines = strings.lines input;
      points = map (xy: let parts = map (ints.parse) (strings.split "," xy); els = lists.elemAt parts; in { x = els 0; y = els 1; }) lines;
    in
    points;


  # surely this is brute-forceable? Let's go for it.
  # Two points that are farthest apart
  part1 =
    let
      p = parse input;

      allPairs = builtins.filter (s: s != null) (lists.flatten (lists.imap
        (l: lp: lists.imap
          (r: rp:
            if l >= r then null
            # or heck, not just furthest apart, we can do the math here.
            else { p1 = lp; p2 = rp; area = (1 + (ints.abs (lp.x - rp.x))) * (1 + (ints.abs (lp.y - rp.y))); }
          )
          p)
        p));

      best = lists.head (builtins.sort (x: y: x.area > y.area) allPairs);
    in
    best.area;
in
{
  inherit part1;
}
