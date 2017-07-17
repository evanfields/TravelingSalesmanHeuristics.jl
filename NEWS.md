## 2017-7-14 ##
- `solve_tsp` accepts an optional `quality_factor` keyword specifying (without units or guarantees) the trade-off between computation time and solution quality.

## 2017-7-13 ##
- Julia version 0.4 is no longer supported.
- Introduced helper function `repetitive_heuristic(distmat, heuristic; keywords...)` for repeating a heuristic with many starting cities. The repetitition is parallelized with a `@threads` loop.
- Using the `repetitive` keyword for `nearest_neighbor` or `cheapest_insertion` is deprecated. Instead, use `repetitive_heuristic(distmat, heuristic; ...)`. 
- The `firstcity` keyword should now be an `Int`, not a `Nullable{Int}`. (For now, backwards compatibility is maintained). If the first city is not specified, a random city is chosen.
- The available path generation heuristics now include farthest insertion. Small experiments suggest farthest insertion is the fastest of the generation heuristics and performs decently well on Euclidean instances.

## 2017-1-26 ##

The previous update broke Julia 0.4 compatibility. Thanks to tkelman for the find and fix. I expect to drop 0.4 support when Julia 0.6 is released.

