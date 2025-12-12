{ lib }:
with lib;
let
  input = builtins.readFile ./input;

  parse = input:
    let
      lines = strings.lines input;
      parsed' = map (builtins.match "^\\[([.#]+)] (.*) \\{(.*)}$") lines;
      parsed = map
        (parts:
          let
            p = lists.elemAt parts;
            goal = map (c: c == "#") (strings.chars (p 0));
            joltage = map (ints.parse) (strings.split "," (p 2));
            l = lists.length goal;

            parseButton = str:
              let
                nums = map (ints.parse) (strings.split "," str);
              in
              builtins.foldl' (btns: el: lists.set btns el true) (lists.gen (_: false) l) nums;

            parseButtons = str:
              let
                btns = strings.split " " str;
                btns' = map (builtins.replaceStrings [ "(" ")" ] [ "" "" ]) btns;
              in
              map parseButton btns';
          in
          if (lists.length goal) != (lists.length joltage) then throw "bad input"
          else {
            btns = parseButtons (p 1);
            inherit goal joltage;
          }
        )
        parsed';
    in
    parsed;


  # We're going for min presses, so do a bredth first search and see what
  # happens
  # Here we gooooo (I already know my CPU is going to die)
  # Note, we can almost certainly make this _way_ more efficient by skipping
  # any states we've seen before to avoid computing cycles, I guess let's do
  # that (state.memo)
  bruteforceProblem = state: states:
    let
      next = lists.head states;
      pushButton = state: btn: lists.imap (i: v: if (lists.elemAt btn i) then ! v else v) state;
    in
    if next.val == state.goal then next.depth
    else if state.memo ? "${toString next.val}" then bruteforceProblem state (lists.tail states)
    else
    # push each button, add to queue, and keep going
      bruteforceProblem (state // { memo = state.memo // { "${toString next.val}" = true; }; }) ((lists.tail states) ++ (map (btn: { depth = next.depth + 1; val = pushButton next.val btn; }) state.btns));

  part1 =
    let
      ps = parse input;
    in
    builtins.foldl' builtins.add 0 (map (p: bruteforceProblem { memo = { }; btns = p.btns; goal = p.goal; } [{ depth = 0; val = (map (_: false) p.goal); }]) ps);


  # gauss jordan
  # We don't do anything super fancy like trying to pick the best pivot because
  # all our values are so small it really shouldn't matter
  reduceMatrix = state:
  if state.col == arr2.width matrix then state
  else
  let
    nextNonZeroRow = 0;
  in
  null;


  # This is a linear programming problem. Fine, let's do it.
  # I've opened my "Introduction to Operations Research" book, found the
  # simplex algorithm, closed it, and decided to try guassian elimination
  # first.
  solveRow = row:
    let
      b = row.joltage;
      size = lists.length row.joltage;
      a = builtins.genList (i: map (btn: if (lists.elemAt btn i) then 1 else 0) row.btns) size;
    in
    {
      inherit a b;
    };

  part2 =
    let
      ps = parse input;
    in
    solveRow (lists.head ps);

in
{
  inherit part1 part2;
}
