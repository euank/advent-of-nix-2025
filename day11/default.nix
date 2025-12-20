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

  # so our goal is to find paths to out. That's the same as summing paths to
  # all the nodes that go to out, etc recursively.
  # Doing that naively probably runs into issues since i.e. we could have a path like:
  solvePart1 = state: q:
    let
      el = lists.head q;
      newq = (lists.tail q) ++ (state.rev."${el}" or [ ]);
      newq' = lists.unique2 newq;
      # because of the order we're traversing, all our children are done, let's look em up and update state.
      paths = builtins.foldl' builtins.add 0 (map (el: state.memo."${el}" or 0) state.fwd."${el}");
    in
    if (lists.length q) == 0 then state.memo.you
    else solvePart1 (state // { memo = state.memo // { "${el}" = paths; }; }) newq';


  part1 =
    let
      p = parse input;
    in
    solvePart1 (p // { memo = { "out" = 1; }; }) p.rev.out;

in
{
  inherit part1;
}
