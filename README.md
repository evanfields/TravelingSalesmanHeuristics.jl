# TravelingSalesmanHeuristics

[![Build Status](https://travis-ci.org/evanfields/TravelingSalesmanHeuristics.jl.svg?branch=master)](https://travis-ci.org/evanfields/TravelingSalesmanHeuristics.jl)
[![codecov.io](https://codecov.io/github/evanfields/TravelingSalesmanHeuristics.jl/coverage.svg?branch=master)](https://codecov.io/github/evanfields/TravelingSalesmanHeuristics.jl?branch=master)

### Overview ###
`TravelingSalesmanHeuristics` is a Julia package containing simple heuristics for the [traveling salesman problem](https://en.wikipedia.org/wiki/Travelling_salesman_problem). 

As of 2017-7-13, `TravelingSalesmanHeuristics` implements the nearest neighbor, farthest insertion, and cheapest insertion strategies for path generation, the 2-opt strategy for path refinement, and a simulated annealing heuristic which can be used for path generation or refinement. A simple spanning tree type lower bound is also implemented.

The documentation consists of this readme and detailed inline documentation for the exported functions `solve_tsp`, `nearest_neighbor`, `farthest_insertion`, `cheapest_insertion`, `two_opt`, `repetitive_heuristic`, and `simulated_annealing`. After installing the package, this inline documentation can be accessed at a Julia REPL, e.g.
```
using TravelingSalesmanHeuristics
?nearest_neighbor
```

This package is both my first Julia package and my first effort in open source software, so I welcome any contributions, suggestions, feature requests, pull requests, criticisms, etc.

### When to use ###
Though the traveling salesman problem is the canonical NP-hard problem, in practice heuristic methods are often unnecessary. Modern integer programming solvers such as CPLEX and Gurobi can quickly provide excellent (even certifiably optimal) solutions. If you are interested in solving TSP instances to optimality, I highly recommend the [JuMP](https://github.com/JuliaOpt/JuMP.jl) package. Even if you are not concerned with obtaining truly optimal solutions, using a MILP solver and allowing a relatively large optimality gap is a promising strategy for finding high quality TSP solutions. If you would like to use an integer programming solver along with JuMP but don't have access to commercial software, [GLPK](https://github.com/JuliaOpt/GLPK.jl) can work well on relatively small instances.

Use of this package is most appropriate when you want decent solutions to small or moderate sized TSP instances with a minimum of hassle: one-off personal projects, if you can't install a mixed integer linear programming solver, prototyping, etc.

A word of warning: the heuristics implemented are
* heuristics, meaning you won't get any optimality guarantees and except on very small instances are unlikely to find the optimal tour;
* general purpose, meaning they do not take advantage of any problem specific structure;
* simple and (hopefully) readable but not terribly high performance, meaning you may have trouble with large instances. In particular the 2-opt path refinement strategy slows down noticeably when there are >400 cities.

### Installation ###
Install the package by typing `Pkg.add("TravelingSalesmanHeuristics")` into a Julia REPL. Load it with `using TravelingSalesmanHeuristics`.

### How to use ###
All problems are specified through a square distance matrix `D` where `D[i,j]` represents the cost of traveling from the `i`-th to the `j`-th city. Your distance matrix need not be symmetric and could probably even contain negative values, though I make no guarantee about behavior when using negative values.

We can generate a quick instance of the planar Euclidean TSP in the unit square as follows:
```
srand(47)
using Distances
n = 50
pts = rand(2, n)
distmat = pairwise(Euclidean(), pts)
```

To get a TSP solution in one line, use the `solve_tsp` function:
```
using TravelingSalesmanHeuristics
path, pathcost = solve_tsp(distmat)
```
You should see some output like the following:
```
julia> path, pathcost = solve_tsp(distmat)
([25, 12, 41, 48, 21, 22, 13, 3, 4, 19  …  35, 30, 31, 1, 5, 14, 46, 44, 39, 25], 5.954281044215408)
```
Notice that the path starts and ends at city 25 and our cost is about 5.95.

You can vary the trade-off between solution time and solution quality with the `quality_factor` keyword:
```
julia> @time solve_tsp(distmat; quality_factor = 1)
  0.000034 seconds (17 allocations: 3.281 KiB)
([22, 21, 48, 41, 12, 25, 39, 44, 46, 14  …  31, 1, 27, 23, 17, 19, 4, 3, 13, 22], 5.960141233105482)

julia> @time solve_tsp(distmat; quality_factor = 75)
  0.010056 seconds (7.43 k allocations: 1.258 MiB)
([28, 9, 42, 36, 32, 34, 47, 20, 27, 23  …  30, 35, 16, 2, 7, 33, 49, 45, 43, 28], 5.690542089798684)
```

For more detailed control over how your TSP instance is solved, use the `nearest_neighbor`, `farthest_insertion`, `cheapest_insertion`, `simulated_annealing`, or `two_opt` functions. For example, we might want to solve our TSP by doing cheapest insertion with a loop on city 1 as our initial path and then refine with 2-opt:

```
julia> path, pathcost = cheapest_insertion(distmat; firstcity = Nullable(1), do2opt = true)
([1,4,14,3,20,8,2,10,11,19  …  5,15,9,18,6,16,13,17,12,1],3.451385584282254)
```

To call a heuristic repeatedly with every possible starting city, use `repetitive_heuristic`:
```
julia> nearest_neighbor(distmat; do2opt = true)
([10, 15, 11, 37, 50, 18, 38, 29, 8, 25  …  35, 30, 31, 1, 5, 14, 40, 26, 6, 10], 5.912552858008369)

julia> repetitive_heuristic(distmat, nearest_neighbor; do2opt = true)
([13, 3, 4, 19, 17, 23, 27, 20, 47, 34  …  25, 39, 46, 44, 12, 41, 48, 21, 22, 13], 5.719611665246735)
```
Note that repetitive heuristics can be quite time consuming, especially if every returned path is refined with two-opt swaps. The repetition is threaded using `@threads`, so the time cost can be ameliorated somewhat by enabling multiple threads as described in [the manual](https://docs.julialang.org/en/stable/manual/parallel-computing/#Multi-Threading-(Experimental)-1).

Finally, we may want to find a lower bound on the optimal cost:
```
julia> lowerbound(distmat)
5.025702988391803
```
