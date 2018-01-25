## Overview

`TravelingSalesmanHeuristics` implements basic heuristics for the [traveling salesman problem](https://en.wikipedia.org/wiki/Travelling_salesman_problem). 
As of 2017-7-13, `TravelingSalesmanHeuristics` implements the nearest neighbor, farthest insertion, and cheapest insertion strategies for path generation, the 2-opt strategy for path refinement, and a simulated annealing heuristic which can be used for path generation or refinement. A simple spanning tree type lower bound is also implemented.

## When to use
Though the traveling salesman problem is the canonical NP-hard problem, in practice heuristic methods are often unnecessary. Modern integer programming solvers such as CPLEX and Gurobi can quickly provide excellent (even certifiably optimal) solutions. If you are interested in solving TSP instances to optimality, I highly recommend the [JuMP](https://github.com/JuliaOpt/JuMP.jl) package. Even if you are not concerned with obtaining truly optimal solutions, using a mixed integer programming solver is a promising strategy for finding high quality TSP solutions. If you would like to use an integer programming solver along with JuMP but don't have access to commercial software, [GLPK](https://github.com/JuliaOpt/GLPK.jl) can work well on relatively small instances.

Use of this package is most appropriate when you want decent solutions to small or moderate sized TSP instances with a minimum of hassle: one-off personal projects, if you can't install a mixed integer linear programming solver, prototyping, etc.

A word of warning: the heuristics implemented are
* heuristics, meaning you won't get any optimality guarantees and, except on very small instances, are unlikely to find the optimal tour;
* general purpose, meaning they do not take advantage of any problem specific structure;
* simple and (hopefully) readable but not terribly high performance, meaning you may have trouble with large instances. In particular the two-opt path refinement strategy slows down noticeably when there are >400 cities.

## Installation
`TravelingSalesmanHeuristics` is a registered package, so you can install it with `Pkg.add("TravelingSalesmanHeuristics")`. Load it with `using TravelingSalesmanHeuristics`.

## Usage
All problems are specified through a square distance matrix `D` where `D[i,j]` represents the cost of traveling from the `i`-th to the `j`-th city. Your distance matrix need not be symmetric and could probably even contain negative values, though I make no guarantee about behavior when using negative values.

!!! note
    Because problems are specified by dense distance matrices, this package is not well suited to problem instances with sparse distance matrix structure, i.e. problems with large numbers of cities where each city is connected to few other cities.

The simplest way to use this package is with the `solve_tsp` function:

```@docs
solve_tsp
```

