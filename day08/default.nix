{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      lines = strings.lines input;
      points = map (xyz: let parts = map (ints.parse) (strings.split "," xyz); els = lists.elemAt parts; in { x = els 0; y = els 1; z = els 2; }) lines;
    in
    points;

  # So the right thing algorithmically is to do a kd tree for 3 dimensions
  # and use a kNN search for the nearest neighbors that way, right?
  # Except, there's only 1000 points, we can just pair them all up, and that's only 1 million pairs.
  # 1 million pairs is easy to compute, let's just do that.
  part1 =
    let
      p = parse input;

      allPairs = builtins.filter (s: s != null) (lists.flatten (lists.imap
        (l: lp: lists.imap
          (r: rp:
            # skip ourselves, and also we can skip half of them by ignoring the
            # symetric pairs, i.e. index 1->2 is the same as 2->1
            if l >= r then null
            # otherwise, compute the distance-squared for this pair of points. We
            # don't need to sqrt because we're just comparing magnitude right.
            else { inherit l r; dist = (ints.pow (rp.x - lp.x) 2) + (ints.pow (rp.y - lp.y) 2) + (ints.pow (rp.z - lp.z) 2); }
          )
          p)
        p));

      pairs = builtins.sort (x: y: x.dist < y.dist) allPairs;

      mergeCircuits = state: rem:
        let
          next = lists.head rem;
          lhs = next.l;
          rhs = next.r;
          lhsCircuit = state.lookup."${toString lhs}" or null;
          rhsCircuit = state.lookup."${toString rhs}" or null;
        in
        if state.numConnections == 1000 then state
        else if lhs == rhs then builtins.throw "This should not happen"
        # This case means they're both in the same circuit already, skip
        else if lhsCircuit != null && lhsCircuit == rhsCircuit then
          mergeCircuits
            {
              inherit (state) circuits lookup;
              numConnections = state.numConnections + 1;
            }
            (lists.tail rem)
        # rhs gets added to lhs circuit
        else if lhsCircuit != null && rhsCircuit == null then
          mergeCircuits
            {
              numConnections = state.numConnections + 1;
              circuits = state.circuits // {
                "${toString lhsCircuit}" = state.circuits."${toString lhsCircuit}" // { "${toString rhs}" = { }; };
              };
              lookup = state.lookup // {
                "${toString rhs}" = lhsCircuit;
              };
            }
            (lists.tail rem)
        # lhs gets added to rhs
        else if rhsCircuit != null && lhsCircuit == null then
          mergeCircuits
            {
              numConnections = state.numConnections + 1;
              circuits = state.circuits // {
                "${toString rhsCircuit}" = state.circuits."${toString rhsCircuit}" // { "${toString lhs}" = { }; };
              };
              lookup = state.lookup // {
                "${toString lhs}" = rhsCircuit;
              };
            }
            (lists.tail rem)
        # both exist, but are in diff circuits. We merge rhs into lhs, and update all of rhs
        else if rhsCircuit != null && lhsCircuit != null then
          mergeCircuits
            {
              numConnections = state.numConnections + 1;
              circuits = (builtins.removeAttrs state.circuits [ "${toString rhsCircuit}" ]) // {
                "${toString lhsCircuit}" = state.circuits."${toString lhsCircuit}" // (state.circuits."${toString rhsCircuit}" // {
                  "${toString rhsCircuit}" = { };
                });
              };
              lookup = builtins.mapAttrs (name: value: if value == rhsCircuit then lhsCircuit else value) state.lookup;
            }
            (lists.tail rem)
        # otherwise neither existed, make a new circuit
        else if rhsCircuit == null && lhsCircuit == null
        then
          mergeCircuits
            {
              numConnections = state.numConnections + 1;
              circuits = state.circuits // {
                "${toString lhs}" = { "${toString rhs}" = { }; };
              };
              lookup = state.lookup // {
                "${toString lhs}" = lhs;
                "${toString rhs}" = lhs;
              };
            }
            (lists.tail rem)
        else builtins.throw "Oops";
      merged = mergeCircuits { numConnections = 0; circuits = { }; lookup = { }; } pairs;
      sizes = map (v: 1 + (builtins.length (builtins.attrNames v))) (builtins.attrValues merged.circuits);
    in
    builtins.foldl' builtins.mul 1 (lists.take 3 (builtins.sort (x: y: x > y) sizes));
in
{
  inherit part1;
}
