{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      lines = strings.lines input;
      # there's 6 shapes in the sample and input, all 3x3, let's assume that's always true
      shapeLines = lists.chunk 5 (lists.take 30 lines);
      puzzleLines = lists.drop 30 lines;

      parseShape = shapeLine:
        let
          ll = lists.take 3 (lists.drop 1 shapeLine);
        in
        map (l: map (c: if c == "#" then 1 else 0) (strings.split "" l)) ll;

      parseLine = line:
        let
          parts = strings.split ": " line;
          axb = map ints.parse (strings.split "x" (lists.elemAt parts 0));
          counts = map ints.parse (strings.split " " (lists.elemAt parts 1));
        in
        {
          w = lists.elemAt axb 0;
          h = lists.elemAt axb 1;
          inherit counts;
        };
    in
    {
      shapes = map parseShape shapeLines;
      regions = map parseLine puzzleLines;
    };


  # If there are so few squares in the area that we can't physically fit all the shape squares, it's impossible. Remove those.
  trimImpossiblePuzzles = p:
    let
      shapeAreas = map (s: lists.sum (map lists.sum s)) p.shapes;
      regionAreas = map (r: let sArea = builtins.foldl' builtins.add 0 (lists.imap (i: c: (lists.elemAt shapeAreas i) * c) r.counts); in r // { area = r.w * r.h; shapeArea = sArea; }) p.regions;
    in
    lists.filter (r: r.area >= r.shapeArea) regionAreas;

  # If there are so many squares in the area that we can fit every present in
  # its own 3x3 square, we have plenty of leeway and don't have to do
  # anything else
  countDefinitelyFitting = p:
    let
      f' = lists.filter (r: let worstCaseArea = builtins.foldl' builtins.add 0 (map (c: c * 9) r.counts); in r.area < worstCaseArea) p;
    in
    {
      plentyOfLeewayCount = (lists.length p) - (lists.length f');
      remaining = f';
    };

  part1 =
    let
      p = parse input;
      trimmedRegions = trimImpossiblePuzzles p;
      trimmed' = countDefinitelyFitting trimmedRegions;
    in
    # Oh, wow, that was easy.
    if (lists.length trimmed'.remaining) > 0 then throw "My input didn't have anything left here, sorry, your input is hard"
    else trimmed'.plentyOfLeewayCount;
in
{
  inherit part1;
}
