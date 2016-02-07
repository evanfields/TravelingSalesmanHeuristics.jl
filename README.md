# TSPHeuristics

[![Build Status](https://travis-ci.org/evanfields/TravelingSalesmanHeuristics.jl.svg?branch=master)](https://travis-ci.org/evanfields/TravelingSalesmanHeuristics.jl)
[![codecov.io](https://codecov.io/github/evanfields/TravelingSalesmanHeuristics.jl/coverage.svg?branch=master)](https://codecov.io/github/evanfields/TravelingSalesmanHeuristics.jl?branch=master)

### Overview ###
`TravelingSalesmanHeuristics` is a Julia package containing simple heuristics for the [traveling salesman problem](https://en.wikipedia.org/wiki/Travelling_salesman_problem). 

As of 2016-2-7, `TravelingSalesmanHeuristics` implements the nearest neighbor and cheapest insertion strategies for path generation and the 2-opt strategy for path refinement. A simple spanning tree type lower bound is also implemented.

This package is both my first Julia package and my first effort in open source software, so I welcome any contributions, suggestions, feature requests, pull requests, criticisms, etc.

## When to use ###
Though the traveling salesman problem is the canonical NP-hard problem, in practice heuristic methods are often unnecessary. Modern integer programming solves such as CPLEX and Gurobi can quickly provide excellent (even certifiably optimal) solutions. If you are interested in solving TSP instances to optimality, I highly recommend the [JuMP](https://github.com/JuliaOpt/JuMP.jl) package. Even if you are not concerned with obtaining truly optimal solutions, using a MILP solver and allowing a relatively large optimality gap is a promising strategy for finding high quality TSP solutions.

Use of this package is most appropriate when you want decent solutions to small or moderate sized TSP instances with a minimum of hassle: one-off personal projects, if you can't install a mixed integer linear programming solver, prototyping, etc.

A word of warning: the heuristics implemented are
* heuristics, meaning you won't get any optimality guarantees and except on very small instances are unlikely to find the optimal tour;
* general purpose, meaning they do not take advantage of any problem specific structure;
* simple and (hopefully) readable but not terribly high performance, meaning you may have trouble with large instances. In particular the 2-opt path refinement strategy slows down noticeably when there are >400 cities.

### How to use ###
All problems are specified through a square distance matrix `D` where `D[i,j]` represents the cost of traveling from the `i`-th to the `j`-th city. Your distance matrix need not be symmetric and could probably even contain negative values, though I make no guarantee about behavior when using negative values.

We can generate a quick instance of the planar Euclidean TSP in the unit square as follows:
```
using Distances
n = 20
pts = rand(2, n)
distmat = pairwise(Euclidean(), pts, pts)
```

To get a TSP solution in one line, use the `solve_tsp` function:
```
using TravelingSalesmanHeuristics
path, pathcost = solve_tsp(distmat)
```
You should see some output like the following:
```
julia> path, pathcost = solve_tsp(distmat)
([6,16,13,20,12,17,1,4,14,3  …  2,10,11,19,7,5,15,9,18,6],3.359749477447318)
```
Notice that the path starts and ends at city 6 and our cost is about 3.36.

For more detailed control over how your TSP instance is solved, use the `nearest_neighbor`, `cheapest_insertion`, or `two_opt` functions. For example, we might want to solve our TSP by doing cheapest insertion with a loop on city 1 as our initial path and then refine with 2-opt:

```
julia> path, pathcost = cheapest_insertion(distmat; firstcity = Nullable(1), do2opt = true)
([1,4,14,3,20,8,2,10,11,19  …  5,15,9,18,6,16,13,17,12,1],3.451385584282254)
```

Finally, we may want to find a lower bound on the optimal cost:
```
julia> lowerbound(distmat)
2.801206595621498
```
