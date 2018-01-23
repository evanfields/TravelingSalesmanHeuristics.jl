This page describes the heuristics currently implemented by this package. The heuristics are split into _path generation_ heuristics, which create an initial path from a problem instance (specified by a distance matrix) and _path refinement_ heuristics which take an input path and attempt to improve it.

### Path generation heuristics
```@docs
nearest_neighbor
```
```@docs
farthest_insertion
```
```@docs
cheapest_insertion
```
