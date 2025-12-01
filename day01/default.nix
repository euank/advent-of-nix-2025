{ lib }:
with lib;
let
  input = builtins.filter (s: s != "") (strings.split "\n" (builtins.readFile ./input));
  step = lines: state:
    if (lists.length lines) == 0 then state
    else
      let
        line = lists.head lines;
        dir = strings.head line;
        num = builtins.fromJSON (strings.tail line);
      in
      step (lists.tail lines) rec {
        n = (ints.mod (state.n + (num * (if dir == "L" then -1 else 1))) 100);
        hist = state.hist ++ [ n ];
      };

  part1 = builtins.foldl' (acc: el: acc + (if el == 0 then 1 else 0)) 0 (step input { n = 50; hist = [ ]; }).hist;

  # part 2 requires us to count the number of times we pass 0, so we can count the number of times mod iterates on something
  # I suspected part2 would require keeping track of history, so I did that
  # in part1, but nope, so I'm just going to implement it from scratch

  part2 = lines: state:
    if (lists.length lines) == 0 then state
    else
      let
        line = lists.head lines;
        dir = strings.head line;
        num = builtins.fromJSON (strings.tail line);
        n = state.n + (num * (if dir == "L" then -1 else 1));

        countMod = state:
          if state.n < 0 then
            countMod
              {
                n = (state.n + 100);
                overflows = state.overflows + 1;
              } else if state.n >= 100 then
            countMod
              {
                n = state.n - 100;
                overflows = state.overflows + 1;
              } else state;

        cm = countMod { inherit n; overflows = 0; };
        # overflows get most things, but they have two special cases when going left:
        # 1. If we turn to 0, but not over it (i.e. at 10, L10), then that counts as hitting 0, but doesn't overflow
        # 2. If we start at 0, and turn left (i.e. at 0, L10), that counts as
        # hitting 0 twice now because above we added 1 for landing on 0, and
        # now we're turning left and overflowing, but that shouldn't be counted
        # since we already counted, so it's a double count. Avoid that too.
        extra = if dir == "L" && cm.n == 0 then 1 else 0;
        avoidExtraOverflow = if dir == "L" && state.n == 0 then (-1) else 0;
      in
      part2 (lists.tail lines) {
        n = cm.n;
        ans = state.ans + cm.overflows + extra + avoidExtraOverflow;
      };
in
{
  inherit part1;
  part2 = (part2 input { n = 50; ans = 0; }).ans;
}
