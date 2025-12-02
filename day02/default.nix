{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      ranges = strings.split "," input;
    in
    map
      (r:
        let p = strings.split "-" r; in {
          from = ints.parse (builtins.elemAt p 0);
          to = ints.parse (builtins.elemAt p 1);
        })
      ranges;

  invalidIDsInRangeOfLen = range: len:
    if (ints.mod len 2) != 0 then [ ]
    else
      let
        hl = len / 2;
        lowerHalfBound = range.from / (ints.pow 10 hl);
        upperHalfBound = 1 + (range.to / (ints.pow 10 hl));

        halfCandidates = builtins.genList (i: i + lowerHalfBound) (upperHalfBound - lowerHalfBound);

        candidates = map (c: c * (ints.pow 10 hl) + c) halfCandidates;
      in
      builtins.filter (c: c >= range.from && c <= range.to && (ints.mod ((strings.length (builtins.toString c))) 2) == 0) candidates;


  # We want to find IDs where the first and second half are the same in a given range
  # If we have a range like:
  #   1-20
  # then we want to find 11.
  # We can do this by generating all repeating IDs of the lengths between the
  # two bounds (i.e. lengths here are 1 and 2), ignoring odd ones (just 2),
  # and then trimming invalid ones.
  # All the ones of length 2 are 11, 22, ... 99, so we get 10 for length 2.
  # This grows exponentially though, so we want to trim them early if we can.
  # If we treat '1' as '01', then we can generate only numbers with the first
  # digit between those two ('0-1', so '00' and '11' only, though the problem
  # says we can ignore leading zeroes so just '11')
  # This ignores the less significant digits, so we'll do a filter to trim anything at the end
  # Due to ignoring the less significant digits, we could certainly do
  # something more efficient.
  invalidIDsInRange = range:
    let
      lowerLen = ints.log10 range.from;
      upperLen = ints.log10 range.to;
    in
    builtins.foldl' (acc: l: acc ++ (invalidIDsInRangeOfLen range l)) [ ] (builtins.genList (i: i + lowerLen) (upperLen - lowerLen + 1));


  part1 =
    let
      p = parse input;
      idsInRanges = map invalidIDsInRange p;
    in
    builtins.foldl' builtins.add 0 (builtins.concatLists idsInRanges);
in
{
  inherit part1;
}
