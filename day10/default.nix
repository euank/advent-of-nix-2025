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
            parseButtons = str:
              let
                btns = strings.split " " str;
                btns' = map (builtins.replaceStrings [ "(" ")" ] [ "" "" ]) btns;
              in
              map (s: map (ints.parse) (strings.split "," s)) btns';
          in
          {
            goal = map (c: c == "#") (strings.chars (p 0));
            btns = parseButtons (p 1);
            joltage = map (ints.parse) (strings.split "," (p 2));
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
      pushButton = state: btn: builtins.foldl' (acc: el: lists.set acc el (! (lists.elemAt acc el))) state btn;
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
in
{
  inherit part1;
}
