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

  doOp = el:
    if el.op == "+" then builtins.foldl' builtins.add 0 el.nums
    else builtins.foldl' builtins.mul 1 el.nums;

  part1 =
    let
      p = parse input;
    in
    lists.sum (map doOp p);


  # Since it depends on the textual spacing, we're stuck redoing the parsing code
  # It looks like the operation is always left-most according to the sample, so
  # let's just find operation indexes, and work based on that
  parse2 = input:
    let
      lines = builtins.filter (s: s != "") (strings.split "\n" input);
      grid = map (strings.split "") lines;
      opLine = lists.last lines;
      opIndexes = builtins.filter (l: l != null) (lists.imap (i: el: if el != " " then i else null) (strings.split "" opLine));
      ranges = builtins.genList (i: { from = elemAt opIndexes i; to = (lists.getDef opIndexes (i + 1) (1 + (strings.length opLine))) - 1; }) (lists.length opIndexes);
      # And now actually get the numbers
      doRange = range:
        let
          size = range.to - range.from;
          columns = map (column: ints.parse (builtins.foldl' (acc: el: "${acc}${el}") "" column)) (builtins.genList (x: builtins.genList (y: arr2.get grid (range.from + x) y) ((lists.length lines) - 1)) size);
        in
        {
          nums = columns;
          op = arr2.get grid range.from ((lists.length lines) - 1);
        };
    in
    map doRange ranges;

  part2 =
    let
      p = parse2 input;
    in
    lists.sum (map doOp p);
in
{
  inherit part1 part2;
}
