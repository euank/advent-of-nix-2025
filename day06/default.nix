{ lib }:
with lib;
let
  elemAt = builtins.elemAt;

  input = builtins.readFile ./input;

  parse = input:
    let
      lines = builtins.filter (s: s != "") (strings.split "\n" input);
      lines' = map (builtins.filter (s: s != "")) (map strings.splitSpace lines);
      numColumns = arr2.width lines';
      height = arr2.height lines';
    in
    builtins.genList
      (x:
        {
          nums = map ints.parse (builtins.genList (y: arr2.get lines' x y) (height - 1));
          op = arr2.get lines' x (height - 1);
        }
      )
      numColumns;

  part1 =
    let
      p = parse input;
      doOp = el:
        if el.op == "+" then builtins.foldl' builtins.add 0 el.nums
        else builtins.foldl' builtins.mul 1 el.nums;
    in
    lists.sum (map doOp p);
in
{
  inherit part1;
}
