rec {

  lists = {
    head = builtins.head;
    tail = builtins.tail;
    length = builtins.length;
    sum = builtins.foldl' builtins.add 0;
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

  traceVal = x: builtins.trace x x;
}
