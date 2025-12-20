{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      lines = strings.lines input;
      parts = map (builtins.match "(.*): (.*)") lines;
      parsePart = parts:
        let
          p = lists.elemAt parts;
        in
        {
          lhs = p 0;
          rhs = strings.split " " (p 1);
        };
      parts' = map parsePart parts;
      # create a forward and then a reverse mapping, from the problem it seems like that'll be useful
      fwd = builtins.listToAttrs (map (el: { name = el.lhs; value = el.rhs; }) parts');
      # rev = builtins.zipAttrsWith (name: values: values) (map builtins.attrValues (builtins.mapAttrs (name: vvs: map (v: { name = v; value = name; }) vvs) fwd));
      rev = builtins.zipAttrsWith (name: values: values) (map (att: { "${att.name}" = att.value; }) (lists.flatten (builtins.attrValues (builtins.mapAttrs (name: vvs: map (v: { name = v; value = name; }) vvs) fwd))));
    in
    {
      inherit fwd rev;
    };



  findPaths = p: from: to:
    let
      findPaths' = state:
        let
          el = lists.head state.q;
          newq = (lists.tail state.q) ++ (p.rev."${el}" or [ ]);
          newq' = lists.unique2 newq;
          # because of the order we're traversing, all our children are done, let's look em up and update state.
          paths = builtins.foldl' builtins.add 0 (map (el: state.memo."${el}" or 0) p.fwd."${el}");
        in
        if (lists.length state.q) == 0 then (state.memo."${from}" or 0)
        else findPaths' (state // { q = newq'; memo = state.memo // { "${el}" = paths; }; });
    in
    findPaths' { q = p.rev."${to}" or [ ]; memo = { "${to}" = 1; }; };

  part1 =
    let
      p = parse input;
    in
    findPaths p "you" "out";

  # So for part2, it seems like we should be able to use the part1 solution, and just do some math,right?
  # Like, the paths from svr -> out that hit both dac and fft should be:
  # paths from svr -> fft * paths from fft -> dac * paths from dac -> out
  # However, the thing is the middle could be fft -> dac, or dac -> fft
  # it can't be both since there's no cycles, so we just have to try both
  part2 =
    let
      p = parse input;
      fftDac = findPaths p "fft" "dac";
      dacFft = findPaths p "dac" "fft";
    in
    if fftDac == 0 then [ (findPaths p "svr" "dac") dacFft (findPaths p "fft" "out") ]
    else (findPaths p "svr" "fft") * fftDac * (findPaths p "dac" "out");

in
{
  inherit part1 part2;
}
