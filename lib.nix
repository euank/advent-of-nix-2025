rec {
  lists = rec {
    elemAt = builtins.elemAt;
    gen = builtins.genList;
    head = builtins.head;
    last = xs: elemAt xs ((length xs) - 1);
    tail = builtins.tail;
    init = xs: gen (n: elemAt xs n) ((length xs) - 1);
    length = builtins.length;
    sum = builtins.foldl' builtins.add 0;

    flatten = builtins.foldl' (acc: x: acc ++ x) [ ];
  };

  strings = rec {
    length = builtins.stringLength;

    head = builtins.substring 0 1;
    tail = s: let len = builtins.stringLength s; in builtins.substring 1 (len - 1) s;

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

  lists = {
    # unique unique's a list for things that can be compared with ==. It does not preserve order.
    # Abuse genericClosure for it since it dedupes lol
    unique = xs: builtins.map (x: x.key) (builtins.genericClosure {
      startSet = builtins.map (x: { key = x; }) xs;
      operator = item: [ item ];
    });
  };

  attrs = rec {
    inherit (builtins) removeAttrs attrNames;
    # taken verbatim from nixpkgs, copyright nix authors etc
    filter = pred: set: removeAttrs set (builtins.filter (name: !pred name set.${name}) (attrNames set));
  };

  ints = rec {
    parse = s: builtins.fromJSON (strings.removePrefix "0" s);

    max = x: y: if x > y then x else y;
    min = x: y: if x < y then x else y;

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

  traceVal = x: builtins.trace x x;
}
