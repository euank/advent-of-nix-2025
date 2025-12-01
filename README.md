## Advent of Nix 2025

This is my go at Advent of Code (2025) in pure nix.

### Running solutions

In general, `nix eval '.#dayX'` (where 'X' is the number of the day, padded to
length 2, such as `nix eval '.#day03'`) will display the answer to a given day.

### Extra constraints

I've decided to avoid the nixpkgs stdlib for as long as possible this time,
vendoring in functionality when I need to.

This choice is entirely arbitrary, and I might change my mind.
