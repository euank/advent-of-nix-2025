rec {
  inherit (builtins) removeAttrs attrNames filter;

  strHead = builtins.substring 0 1;
  strTail = s: let len = builtins.stringLength s; in builtins.substring 1 (len - 1) s;

  hasPrefix = prefix: str:
  if (builtins.stringLength prefix) == 0 then true
  else if (builtins.stringLength str) == 0 then false
  else if (strHead prefix) == (strHead str) then hasPrefix (strTail prefix) (strTail str)
  else false;

  # taken verbatim from nixpkgs, copyright nix authors etc
  filterAttrs = pred: set: removeAttrs set (filter (name: !pred name set.${name}) (attrNames set));
}
