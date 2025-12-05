{ lib }:
with lib;
let
  elemAt = builtins.elemAt;

  input = builtins.readFile ./input;

  parse = input:
    let
      parts = strings.split "\n\n" input;

      parseRange = range:
        let parts = strings.split "-" range; in { from = ints.parse (elemAt parts 0); to = ints.parse (elemAt parts 1); };

      ranges = map parseRange (strings.split "\n" (elemAt parts 0));
      excludes = map ints.parse (builtins.filter (s: s != "") (strings.split "\n" (elemAt parts 1)));
    in
    {
      inherit ranges excludes;
    };


  mergeRanges = data:
    let
      sorted = builtins.sort (lhs: rhs: if lhs.from == rhs.from then lhs.to < rhs.to else lhs.from < rhs.from) data.ranges;
      mergePair = lhs: rhs:
        # no overlap
        if lhs.to < rhs.from then [ lhs rhs ]
        # some overlap or the ends touch, we can merge them
        else [{ from = ints.min lhs.from rhs.from; to = ints.max lhs.to rhs.to; }];

      merged = builtins.foldl' (acc: el: (lists.init acc) ++ (mergePair (lists.last acc) el)) [ (lists.head sorted) ] (lists.tail sorted);
    in
    {
      ranges = merged;
      excludes = builtins.sort builtins.lessThan data.excludes;
    };

  countFresh = data:
    let
      cur = lists.head data.excludes;
      curRange = lists.head data.ranges;
    in
    if (lists.length data.ranges) == 0 then 0
    else if (lists.length data.excludes) == 0 then 0
    else if cur > curRange.to then
      (countFresh {
        ranges = lists.tail data.ranges;
        excludes = data.excludes;
      }) else (if cur < curRange.from then 0 else 1) + (countFresh {
      ranges = data.ranges;
      excludes = lists.tail data.excludes;
    });



  part1 =
    let
      data = mergeRanges (parse input);
    in
    countFresh data;

in
{
  inherit part1;
}
