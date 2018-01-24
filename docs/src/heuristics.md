This page describes the heuristics currently implemented by this package. The heuristics are split into *path generation* heuristics, which create an initial path from a problem instance (specified by a distance matrix) and *path refinement* heuristics which take an input path and attempt to improve it.

## Path generation heuristics
```@docs
nearest_neighbor
```
```@docs
farthest_insertion
```
```@docs
cheapest_insertion
```

## Path refinement heuristics
```@docs
two_opt
```
```@docs
simulated_annealing
```

## Repetitive heuristics
Many of the heuristics in this package require some starting state. For example, the nearest neighbor heuristic begins at a first city and then iteratively continues to whichever unvisited city is closest to the current city. Therefore, running the heuristic with different choices for the first city may produce different final paths. At the cost of increased computation time, a better path can often be found by starting the heuristic method at each city. The convenience method `repetitive_heuristic` is provided to help with this use case:
```@docs
repetitive_heuristic
```


## Lower bounds
A simple lower bound on the cost of the optimal tour is provided. This bound uses no problem-specific structure; if you know some details of your problem instance, you can probably find a tighter bound.
```@docs
lowerbound
```
