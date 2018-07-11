## 2018-7-11 ##
- New version with support for Julia 0.7; dropped support for previous Julia versions.

## 2018-1-25 ##
- The package now has proper documentation (built with Documenter).
- A wider variety of types should be supported; e.g. your distance matrix can have `Rational` arguments, initial paths can be `AbstractVectors`, etc.
- `simulated_annealing` will no longer sometimes return a worse path than you pass it.
- `lowerbound` checks that your problem instance is symmetric before using spanning tree bounds.

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

