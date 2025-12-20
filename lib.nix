rec {
  isNull = builtins.isNull;

  trivial = {
    id = x: x;
  };

  lists = rec {
    inherit (builtins) elemAt head tail length filter;
    getDef = arr: idx: def: if idx >= (length arr) then def else elemAt arr idx;
    gen = builtins.genList;
    last = xs: elemAt xs ((length xs) - 1);
    init = xs: gen (n: elemAt xs n) ((length xs) - 1);
    sum = builtins.foldl' builtins.add 0;
    reverse = xs: builtins.genList (i: elemAt xs ((length xs) - i - 1)) (length xs);

    swap = xs: x: x': imap (i: el: if i == x then (elemAt xs x') else if i == x' then (elemAt xs x) else el) xs;

    firstIndexOf = arr: f: if (length arr) == 0 then null else if f (head arr) then 0 else let subIdx = firstIndexOf (tail arr) f; in if subIdx == null then null else 1 + subIdx;

    lastIndexOf = arr: f: let fi = firstIndexOf (reverse arr) f; in if fi == null then null else (length arr) - fi - 1;

    set = arr: idx: val: imap (i: el: if i == idx then val else el) arr;

    drop = n: arr: if n == 0 then arr else if (length arr) == 0 then throw "dropping empty list" else drop (n - 1) (tail arr);

    take = n: arr:
      if n == 0 then [ ]
      else [ (head arr) ] ++ (take (n - 1) (tail arr));

    imap = f: arr: builtins.genList (i: f i (elemAt arr i)) (length arr);

    flatten = builtins.foldl' (acc: x: acc ++ x) [ ];

    any = pred: xs: if (length xs) == 0 then false else if (pred (head xs)) then true else (any pred (tail xs));
    all = pred: xs: if (length xs) == 0 then true else if ! (pred (head xs)) then false else (all pred (tail xs));

    # unique unique's a list for things that can be compared with ==. It does not preserve order.
    # Abuse genericClosure for it since it dedupes lol
    unique = xs: builtins.map (x: x.key) (builtins.genericClosure {
      startSet = builtins.map (x: { key = x; }) xs;
      operator = item: [ item ];
    });

    # unique2 is unique, but it preserves order. It removes the last elements that are dupes.
    # It only works on lists that can be 'toString'd
    unique2 = xs:
      let
        unique2' = xs: state:
          if (length xs) == 0 then [ ]
          else if (state ? "${toString (head xs)}") then unique2' (tail xs) state
          else [ (head xs) ] ++ (unique2' (tail xs) (state // { "${toString (head xs)}" = true; }));
      in
      unique2' xs { };
  };

  strings = rec {
    length = builtins.stringLength;

    lines = input: split "\n" (trimSuffix "\n" input);

    trimSuffix = suffix: str: if (last str) == suffix then trimSuffix suffix (init str) else str;

    head = builtins.substring 0 1;
    last = s: builtins.substring ((length s) - 1) 1 s;
    tail = s: let len = builtins.stringLength s; in builtins.substring 1 (len - 1) s;
    init = s: builtins.substring 0 ((length s) - 1) s;

    chars = split "";

    split = sep: str:
      let
        sepLen = length sep;
        strLen = length str;
        isSep = (builtins.substring 0 sepLen str) == sep;
        rest = if isSep then (split sep (builtins.substring sepLen (strLen - sepLen) str)) else (split sep (builtins.substring 1 (strLen - 1) str));
      in
      if strLen < sepLen then [ str ]
      else if strLen == 0 then [ ]
      else if sepLen == 0 then [ (builtins.substring 0 1 str) ] ++ (split sep (builtins.substring 1 (strLen - 1) str))
      else if isSep then [ "" ] ++ rest
      else
        let restHead = lists.head rest;
        in [ ((head str) + restHead) ] ++ (lists.tail rest);

    splitSpace = str: builtins.filter builtins.isString (builtins.split "[ \t]+" str);


    hasPrefix = prefix: str:
      if (builtins.stringLength prefix) == 0 then true
      else if (builtins.stringLength str) == 0 then false
      else if (head prefix) == (head str) then hasPrefix (tail prefix) (tail str)
      else false;

    removePrefix = p: s:
      if hasPrefix p s then builtins.substring (length p) ((length p) - (length s)) s
      else s;

    removePrefix' = p: s:
      if hasPrefix p s then removePrefix' (builtins.substring (length p) ((length p) - (length s)) s)
      else s;
  };

  attrs = rec {
    inherit (builtins) removeAttrs attrNames;
    # taken verbatim from nixpkgs, copyright nix authors etc
    filter = pred: set: removeAttrs set (builtins.filter (name: !pred name set.${name}) (attrNames set));
  };

  floats = rec {
    # isInt returns if 'f' is within 1e6 of the nearest integer value, so like
    # '1.999999' or '2.000001' type things, i.e. floating point errors suck.
    # If it 'isInt', then 'floats.round' may be used to cast to an int.
    isInt = f:
      let
        eps = 1.0e-6;
      in
      (ints.abs (f - (round f))) < eps;

    round = x: builtins.floor (x + 0.5);
  };

  ints = rec {
    parse = s: let trimmed = strings.removePrefix "0" s; in if trimmed == "" && s != "" then 0 else builtins.fromJSON trimmed;

    max = x: y: if x > y then x else y;
    min = x: y: if x < y then x else y;

    abs = x: if x < 0 then x * (-1) else x;

    mod = x: y:
      if x < 0 then (mod (x + y) y)
      else if x >= y then (mod (x - y) y)
      else x;

    log10 = v: if v == 0 then 0 else 1 + (log10 (v / 10));

    pow =
      x: n:
      if n == 0 then
        1
      else if (mod n 2) == 0 then
        pow (x * x) (n / 2)
      else
        x * (pow (x * x) ((n - 1) / 2));
  };

  # arr2 contains functions for dealing with 2d arrays
  arr2 = rec {
    inherit (builtins) length elemAt genList head;

    width = arr: if (length arr) == 0 then 0 else length (elemAt arr 0);
    height = length;

    get =
      arr: x: y:
      elemAt (elemAt arr y) x;

    set =
      arr: x: y: val:
      imap
        (
          x': y': el:
          if x == x' && y == y' then val else el
        )
        arr;

    getDef =
      arr: x: y: def:
      if x < 0 || y < 0 then
        def
      else if x >= (width arr) || y >= (height arr) then
        def
      else
        elemAt (elemAt arr y) x;

    map = f: arr: genList (y: genList (x: f (get arr x y)) (length (head arr))) (length arr);
    imap = f: arr: genList (y: genList (x: f x y (get arr x y)) (length (head arr))) (length arr);

    getColumn = arr: col: builtins.genList (y: get arr col y) (height arr);

    swapRow = m: row: row2:
      lists.set (lists.set m row (elemAt m row2)) row2 (elemAt m row);


    swap =
      arr: x: y: x': y':
      let
        el = get arr x y;
        el' = get arr x' y';
      in
      imap
        (
          xx: yy: orig:
          if xx == x && yy == y then
            el'
          else if xx == x' && yy == y' then
            el
          else
            orig
        )
        arr;
  };

  option = {
    map = f: val: if val == null then null else f val;
  };

  traceVal = x: builtins.trace x x;

  seq = s: builtins.deepSeq s s;
}
