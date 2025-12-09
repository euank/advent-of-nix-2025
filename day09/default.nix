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

  computeAreas = p:
    builtins.filter (s: s != null) (lists.flatten (lists.imap
      (l: lp: lists.imap
        (r: rp:
          if l >= r then null
          # or heck, not just furthest apart, we can do the math here.
          else { p1 = lp; p2 = rp; area = (1 + (ints.abs (lp.x - rp.x))) * (1 + (ints.abs (lp.y - rp.y))); }
        )
        p)
      p));


  # surely this is brute-forceable? Let's go for it.
  # Two points that are farthest apart
  part1 =
    let
      p = parse input;
      allPairs = computeAreas p;
      best = lists.head (builtins.sort (x: y: x.area > y.area) allPairs);
    in
    best.area;


  # Okay, much harder whew
  # For part 2, we can still use the full list we computed before.
  # We can probably walk down the largest areas and try to filter any that aren't fully contained within the green area...
  # There's no interier hollows, so we only have to check if all the parimeter is okay, because if it all is then the interior is too.
  # That would also only happen if a perimeter line intersects the rectangle area, let's try that.

  rectangleDoesntIntersectEdge = rect: line:
    let
      r = {
        min = {
          x = ints.min rect.p1.x rect.p2.x;
          y = ints.min rect.p1.y rect.p2.y;
        };
        max = {
          x = ints.max rect.p1.x rect.p2.x;
          y = ints.max rect.p1.y rect.p2.y;
        };
      };
      l = {
        min = {
          y = ints.min line.from.y line.to.y;
          x = ints.min line.from.x line.to.x;
        };
        max = {
          y = ints.max line.from.y line.to.y;
          x = ints.max line.from.x line.to.x;
        };
      };
    in
    if line.from.x == line.to.x then !(r.min.x < line.from.x && r.max.x > line.from.x && !(r.min.y >= l.max.y || r.max.y <= l.min.y))
    else !(r.min.y < line.from.y && r.max.y > line.from.y && !(r.min.x >= l.max.x || r.max.x <= l.min.x));

  part2 =
    let
      p = parse input;
      allPairs = builtins.sort (x: y: x.area > y.area) (computeAreas p);
      perimLines = computePerims (p ++ [ (lists.head p) ]);
      computePerims = points:
        if (lists.length points) == 1 then [ ]
        else [{ from = (lists.head points); to = (lists.head (lists.tail points)); }] ++ (computePerims (lists.tail points));
      validCandidate = candidate: lists.all (edge: rectangleDoesntIntersectEdge candidate edge) perimLines;

      findContained = rem:
        if (lists.length rem) == 0 then throw "Oh no"
        else if validCandidate (lists.head rem) then (lists.head rem)
        else findContained (lists.tail rem);
    in
    (findContained (seq allPairs)).area;
in
{
  inherit part1 part2;
}
