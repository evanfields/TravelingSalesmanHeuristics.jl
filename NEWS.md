## 2017-7-13 ##
- Julia version 0.4 is no longer supported.
- Introduced helper function `repetitive_heuristic(distmat, heuristic; keywords...)` for repeating a heuristic with many starting cities. The repetitition is parallelized with a `@threads` loop.
- Using the `repetitive` keyword for `nearest_neighbor` or `cheapest_insertion` is deprecated. Instead, use `repetitive_heuristic(distmat, heuristic; ...)`. 
- The `firstcity` keyword should now be an `Int`, not a `Nullable{Int}`. (For now, backwards compatibility is maintained). If the first city is not specified, a random city is chosen.

## 2017-1-26 ##

The previous update broke Julia 0.4 compatibility. Thanks to tkelman for the find and fix. I expect to drop 0.4 support when Julia 0.6 is released.

