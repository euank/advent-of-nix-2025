{ lib }:
with lib;
let
  input = builtins.readFile ./input;
  grid = map (strings.split "") (builtins.filter (s: s != "") (strings.split "\n" input));

  canAccess = grid: x: y:
    let
      dirs = [
        { x = -1; y = -1; }
        { x = 0; y = -1; }
        { x = 1; y = -1; }
        { x = -1; y = 0; }
        { x = 1; y = 0; }
        { x = -1; y = 1; }
        { x = 0; y = 1; }
        { x = 1; y = 1; }
      ];
    in
    (builtins.foldl' (acc: el: acc + (if ((arr2.getDef grid (x + el.x) (y + el.y) ".") == "@") then 1 else 0)) 0 dirs) < 4;
  doPart1 = grid:
    builtins.foldl' builtins.add 0 (lists.flatten (arr2.imap (x: y: el: if el == "@" && (canAccess grid x y) then 1 else 0) grid));

  part1 = doPart1 grid;

  doPart2 = grid:
    let
      # this time's accessed
      vals = arr2.imap (x: y: el: if el == "@" && (canAccess grid x y) then 1 else 0) grid;
      # update grid
      grid' = arr2.imap (x: y: val: if (arr2.get vals x y) == 1 then "." else val) grid;
      accessed = builtins.foldl' builtins.add 0 (lists.flatten vals);
    in
    if accessed == 0 then 0
    else accessed + (doPart2 grid');

  part2 = doPart2 grid;

in
{
  inherit part1 part2;
}
