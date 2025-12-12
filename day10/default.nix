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


  # gauss jordan, and hopefully brute-force after that
  reduceMatrix = state:
    let
      matrix = state.matrix;
      col = arr2.getColumn matrix state.col;
      # Find the next vertical value that's non-zero below or at current row
      dropped = lists.drop state.row col;
      next = option.map (n: state.row + n) (lists.firstIndexOf dropped (el: el != 0));
      nextVal = lists.elemAt col next;
      # swap it into place
      matrix' = arr2.swapRow matrix state.row next;
      b' = lists.swap state.b state.row next;
      # divide all values in the row by the val
      matrix'' = arr2.imap (x: y: el: if y == state.row then 1.0 * el / nextVal else el) matrix';
      b'' = lists.imap (x: el: if x == state.row then 1.0 * el / nextVal else el) b';

      # zero out the rows below this one by subtracting rows
      rowMul = y: 1.0 * (arr2.get matrix'' state.col y) / (arr2.get matrix'' state.col state.row);
      matrix''' = arr2.imap (x: y: el: if y > state.row then el - ((arr2.get matrix'' x state.row) * (rowMul y)) else el) matrix'';
      b''' = lists.imap (y: by: if y > state.row then by - ((lists.elemAt b'' state.row) * (rowMul y)) else by) b'';
    in
    if state.col == (arr2.width state.matrix) || state.row == (arr2.height state.matrix) then state // { unknowns = state.unknowns ++ (builtins.genList (i: i + state.col) ((arr2.width state.matrix) - state.col)); }
    else if next == null then
      reduceMatrix
        {
          unknowns = state.unknowns ++ [ state.col ];
          col = state.col + 1;
          row = state.row;
          matrix = state.matrix;
          b = state.b;
        }
    else
      reduceMatrix {
        unknowns = state.unknowns;
        col = state.col + 1;
        row = state.row + 1;
        matrix = matrix''';
        b = b''';
      };

  bruteforceSolve = reduced:
    # We're reduced, we have a list of unknowns, let's just try every value we can for them and see how it goes.
    # Our maxes look like ~50-ish, but just in case we need more room after
    # elimination, use a bigger number I guess?
    let
      A = reduced.matrix;
      b = reduced.b;
      width = arr2.width A;
      height = arr2.height A;
      unknowns = reduced.unknowns;
      allCols = builtins.genList (i: i) width;
      pivotCols = lists.filter (c: !(lists.any (u: u == c) unknowns)) allCols;


      maxB = builtins.foldl' ints.max 0.0 (map ints.abs b);
      hi = builtins.floor (maxB * 2.0);
      range = builtins.genList trivial.id hi;

      pivotCol = r:
        let
          rowVals = builtins.genList (c: { col = c; val = arr2.get A c r; }) width;
          pivotRowVals = lists.filter (x: (lists.any (pc: pc == x.col) pivotCols) && x.val != 0.0) rowVals;
        in
        if pivotRowVals == [ ] then null else (lists.head pivotRowVals).col;

      solveWithUnknowns = xUnknowns:
        let
          assigned = lists.filter (idx: (lists.elemAt xUnknowns idx) != null) unknowns;
          b' = lists.imap (r: br: builtins.foldl' (acc: idx: let aval = arr2.get A idx r; xv = lists.elemAt xUnknowns idx; in acc - (1.0 * aval * xv)) br assigned) b;
          xs0 = builtins.genList (_: null) width;
          xs1 = builtins.foldl' (vec: idx: lists.set vec idx (lists.elemAt xUnknowns idx)) xs0 unknowns;

          # back-substitution from bottom row up
          solveRows = r: xs:
            if r < 0 then xs else
            let pc = pivotCol r; in
            if pc == null then if (floats.isInt (lists.elemAt b' r)) then solveRows (r - 1) xs else null
            else
            let
              el = arr2.get A pc r;
              rhs = builtins.foldl'
                (acc: c:
                  let
                    xv = lists.elemAt xs c;
                    aval = arr2.get A c r;
                    isUnknown = lists.any (u: u == c) unknowns;
                  in
                  if xv == null || c == pc || isUnknown then acc else acc - (1.0 * aval * xv)
                )
                (lists.elemAt b' r)
                allCols;
              val = rhs / (1.0 * el);
            in
            if !(floats.isInt val) || val < 0.0
            then null
            else
              let xs' = lists.set xs pc (floats.round val); in
              solveRows (r - 1) xs';
          xsSolved = solveRows (height - 1) xs1;

          xsFilled =
            if xsSolved == null then null else
            lists.imap
              (i: x:
                if x != null then x else
                let
                  col = arr2.getColumn A i;
                  allZero = lists.all (v: v == 0.0) col;
                in
                if allZero then 0 else null
              )
              xsSolved;

          checkRow = r:
            let
              lhs = builtins.foldl' (acc: c: acc + ((arr2.get A c r) * (lists.elemAt xsFilled c))) 0.0 allCols;
              diff = ints.abs (lhs - (lists.elemAt b r));
            in
            diff < 1.0e-4;
          ok =
            xsFilled != null &&
            (lists.all checkRow (builtins.genList (i: i) height));
        in
        if !ok then null else
        builtins.foldl' builtins.add 0 xsFilled;

      search = i: curUnknowns: curSum: best:
        if i >= (lists.length unknowns) then
          let res = solveWithUnknowns curUnknowns; in
          if res == null then best else if best == null then res else ints.min res best
        else
          let
            idx = lists.elemAt unknowns i;
            step = v: bbest:
              let
                # prune by current sum
                bbest' = if bbest != null && (curSum + v) >= bbest then bbest else
                let curUnknowns' = lists.set curUnknowns idx v; in
                search (i + 1) curUnknowns' (curSum + v) bbest;
              in
              bbest';
          in
          builtins.foldl' (acc: v: step v acc) best range;

      initialUnknown = builtins.genList (_: null) width;
      best = search 0 initialUnknown 0 null;
    in
    best;



  # This is a linear programming problem. Fine, let's do it.
  # I've opened my "Introduction to Operations Research" book, found the
  # simplex algorithm, closed it, and decided to try guassian elimination +
  # bruteforce first.
  solveRow = row:
    let
      b = row.joltage;
      size = lists.length row.joltage;
      a = builtins.genList (i: map (btn: if (lists.elemAt btn i) then 1 else 0) row.btns) size;
      reduced = (reduceMatrix {
        col = 0;
        row = 0;
        matrix = a;
        inherit b;
        unknowns = [ ];
      });
    in
    bruteforceSolve reduced;

  part2 =
    let
      ps = parse input;
      solutions = map solveRow ps;
    in
    builtins.foldl' builtins.add 0 solutions;

in
{
  inherit part1 part2;
}
