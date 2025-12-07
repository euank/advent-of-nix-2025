{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      splitterIndexes = map (line: let chars = strings.split "" line; in builtins.filter (el: el != null) (lists.imap (i: el: if el == "^" then i else null) chars)) (builtins.filter (s: s != "") (strings.split "\n" input));
      startIndex = lists.head (builtins.filter (s: s != null) (lists.imap (i: el: if el == "S" then i else null) (strings.split "" input)));
    in
    {
      splitters = splitterIndexes;
      start = startIndex;
    };

  part1 =
    let
      p = parse input;
      doSplit = beams: splitters:
        let
          beams' = (builtins.sort builtins.lessThan (lists.unique beams));
          splitters' = builtins.sort builtins.lessThan splitters;
          nextBeam = lists.head beams';
          nextSplitter = lists.head splitters';
        in
        if (lists.length beams) == 0 || (lists.length splitters) == 0 then { beams = beams'; splits = 0; }
        else if nextBeam == nextSplitter then let s = (doSplit (lists.tail beams') splitters'); in { beams = [ (nextBeam - 1) (nextBeam + 1) ] ++ s.beams; splits = 1 + s.splits; }
        else if nextBeam < nextSplitter then let s = doSplit (lists.tail beams') splitters; in { beams = [ nextBeam ] ++ s.beams; splits = s.splits; }
        else let s = doSplit beams' (lists.tail splitters'); in { beams = s.beams; splits = s.splits; };

      endState = builtins.foldl' (state: line: let lineRes = doSplit state.beams line; in { splits = state.splits + lineRes.splits; beams = lineRes.beams; }) { splits = 0; beams = [ p.start ]; } p.splitters;
    in
    endState.splits;
in
{
  inherit part1;
}
