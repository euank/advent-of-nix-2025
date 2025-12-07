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

  run =
    let
      p = parse input;
      doSplit = beams: splitters: paths:
        let
          beams' = (builtins.sort builtins.lessThan (lists.unique beams));
          splitters' = builtins.sort builtins.lessThan splitters;
          nextBeam = lists.head beams';
          nextSplitter = lists.head splitters';
          pathsIfSplit = paths // {
            "${toString (nextSplitter + 1)}" = (paths."${toString nextSplitter}") + (paths."${toString (nextSplitter + 1)}" or 0);
            "${toString (nextSplitter - 1)}" = (paths."${toString nextSplitter}") + (paths."${toString (nextSplitter - 1)}" or 0);
            "${toString nextSplitter}" = 0;
          };
        in
        if (lists.length beams) == 0 || (lists.length splitters) == 0 then { paths = paths; beams = beams'; splits = 0; }
        else if nextBeam == nextSplitter then let s = (doSplit (lists.tail beams') splitters' pathsIfSplit); in { paths = s.paths; beams = [ (nextBeam - 1) (nextBeam + 1) ] ++ s.beams; splits = 1 + s.splits; }
        else if nextBeam < nextSplitter then let s = doSplit (lists.tail beams') splitters paths; in { paths = s.paths; beams = [ nextBeam ] ++ s.beams; splits = s.splits; }
        else doSplit beams' (lists.tail splitters') paths;

      endState = builtins.foldl' (state: line: let lineRes = doSplit state.beams line state.paths; in { paths = lineRes.paths; splits = state.splits + lineRes.splits; beams = lineRes.beams; }) { paths = { "${toString p.start}" = 1; }; splits = 0; beams = [ p.start ]; } p.splitters;
    in
    endState;

  part1 = run.splits;
  part2 = lists.sum (builtins.attrValues run.paths);
in
{
  inherit part1 part2;
}
