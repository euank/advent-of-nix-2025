## Advent of Nix 2025

These are my solutions to Advent of Code (2025) in pure nix.

### Running solutions

For almost all solutions you'll need to invoke them as:

```
$ ulimit -s unlimited
$ nix eval --max-call-depth 2147483648 '.#dayXX'
```

In general, `nix eval '.#dayX'` (where 'X' is the number of the day, padded to
length 2, such as `nix eval '.#day03'`) will display the answer to a given day.

### Extra constraints

I've decided to avoid the nixpkgs stdlib this time.
I've vendored a small number of functions into 'lib.nix', but for the most part
I've derived library functions in lib.nix myself as needed.

## Performance

This time things aren't too bad!

This is the first time I can execute all of the solutions in one shot!

```
$ time nix eval --max-call-depth 2147483648 '.#all'
...
1746.92s  user 13.72s system 315% cpu 9:17.65 total
max memory: 87637 MB
```

Under 10 minutes, under 100GiB :D

### CPU Time (User + System)

```mermaid
xychart-beta
    title "CPU Time (User + System)"
    x-axis [day01, day02, day03, day04, day05, day06, day07, day08, day09, day10, day11, day12]
    y-axis "Time (seconds)" 0 --> 280
    bar [1.43, 0.04, 0.35, 3.80, 0.78, 0.54, 1.02, 111.22, 258.58, 279.46, 0.63, 0.68]
```

### Wall Clock Time

```mermaid
xychart-beta
    title "Wall Clock Time"
    x-axis [day01, day02, day03, day04, day05, day06, day07, day08, day09, day10, day11, day12]
    y-axis "Time (seconds)" 0 --> 280
    bar [0.71, 0.05, 0.36, 3.70, 0.59, 0.46, 0.61, 23.53, 67.21, 276.77, 0.58, 0.50]
```

### Peak Memory Usage

```mermaid
xychart-beta
    title "Peak Memory Usage"
    x-axis [day01, day02, day03, day04, day05, day06, day07, day08, day09, day10, day11, day12]
    y-axis "Memory (GB)" 0 --> 52
    bar [0.94, 0.05, 0.50, 0.55, 0.60, 0.55, 0.55, 20.52, 51.84, 0.72, 0.51, 0.73]
```
