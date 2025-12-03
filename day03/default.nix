{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  lines = builtins.filter (s: s != "") (strings.split "\n" input);

  max = x: y: if x > y then x else y;
  max2 = arr:
    let
      h = lists.head arr;
      t = lists.tail arr;
      rm = max2 t;
    in
    if (builtins.length arr) == 2 then { l = h; r = builtins.head t; }
    else if h >= rm.l then { l = h; r = max rm.l rm.r; }
    else rm;

  part1 =
    let
      maxes = map (line: max2 (map ints.parse (strings.split "" line))) lines;
    in
    lists.sum (map (pair: pair.l * 10 + pair.r) maxes);

  # maximum 'n-digit' number formed left-to-right from an array of numbers, i.e. (maxn [ 8 9 1 ] 2) == 91
  maxn = arr: n:
    let
      h = lists.head arr;
      t = lists.tail arr;
      rm = maxn t n;
    in
    if n == 0 then [ ]
    else if (builtins.length arr) == n then arr
    else if h >= (builtins.head rm) then [ h ] ++ (maxn rm (n - 1))
    else rm;

  part2 =
    let
      maxes = map (line: maxn (map ints.parse (strings.split "" line)) 12) lines;
    in
    lists.sum (map (m: ints.parse (builtins.foldl' (acc: x: "${acc}${toString x}") "" m)) maxes);

in
{
  inherit part1 part2;
}
