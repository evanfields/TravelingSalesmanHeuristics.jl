var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "TravelingSalesmanHeuristics implements basic heuristics for the traveling salesman problem.  As of 2017-7-13, TravelingSalesmanHeuristics implements the nearest neighbor, farthest insertion, and cheapest insertion strategies for path generation, the 2-opt strategy for path refinement, and a simulated annealing heuristic which can be used for path generation or refinement. A simple spanning tree type lower bound is also implemented."
},

{
    "location": "index.html#When-to-use-1",
    "page": "Home",
    "title": "When to use",
    "category": "section",
    "text": "Though the traveling salesman problem is the canonical NP-hard problem, in practice heuristic methods are often unnecessary. Modern integer programming solvers such as CPLEX and Gurobi can quickly provide excellent (even certifiably optimal) solutions. If you are interested in solving TSP instances to optimality, I highly recommend the JuMP package. Even if you are not concerned with obtaining truly optimal solutions, using a mixed integer programming solver is a promising strategy for finding high quality TSP solutions. If you would like to use an integer programming solver along with JuMP but don\'t have access to commercial software, GLPK can work well on relatively small instances.Use of this package is most appropriate when you want decent solutions to small or moderate sized TSP instances with a minimum of hassle: one-off personal projects, if you can\'t install a mixed integer linear programming solver, prototyping, etc.A word of warning: the heuristics implemented areheuristics, meaning you won\'t get any optimality guarantees and, except on very small instances, are unlikely to find the optimal tour;\ngeneral purpose, meaning they do not take advantage of any problem specific structure;\nsimple and (hopefully) readable but not terribly high performance, meaning you may have trouble with large instances. In particular the two-opt path refinement strategy slows down noticeably when there are >400 cities."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "TravelingSalesmanHeuristics is a registered package, so you can install it with Pkg.add(\"TravelingSalesmanHeuristics\"). Load it with using TravelingSalesmanHeuristics."
},

{
    "location": "index.html#TravelingSalesmanHeuristics.solve_tsp",
    "page": "Home",
    "title": "TravelingSalesmanHeuristics.solve_tsp",
    "category": "function",
    "text": "solve_tsp(distmat; quality_factor = 40)\n\nApproximately solve a TSP by specifying a distance matrix. Return a tuple (path, cost).\n\nThe optional keyword quality_factor (real number in [0,100]; defaults to 40) specifies the tradeoff between computation time and quality of solution returned. Higher values tend to lead to better solutions found at the cost of more computation time. \n\nnote: Note\nIt is not guaranteed that a call with a high quality_factor will always run slower or  return a better solution than a call with a lower quality_factor, though this is  typically the case. A quality_factor of 100 neither guarantees an optimal solution nor the best solution  that can be found via extensive use of the methods in this package.\n\nSee also...\n\n\n\n"
},

{
    "location": "index.html#Usage-1",
    "page": "Home",
    "title": "Usage",
    "category": "section",
    "text": "All problems are specified through a square distance matrix D where D[i,j] represents the cost of traveling from the i-th to the j-th city. Your distance matrix need not be symmetric and could probably even contain negative values, though I make no guarantee about behavior when using negative values.note: Note\nBecause problems are specified by dense distance matrices, this package is not well suited to problem instances with sparse distance matrix structure, i.e. problems with large numbers of cities where each city is connected to few other cities.The simplest way to use this package is with the solve_tsp function:solve_tsp"
},

{
    "location": "heuristics.html#",
    "page": "Heuristics",
    "title": "Heuristics",
    "category": "page",
    "text": "This page describes the heuristics currently implemented by this package. The heuristics are split into path generation heuristics, which create an initial path from a problem instance (specified by a distance matrix) and path refinement heuristics which take an input path and attempt to improve it."
},

{
    "location": "heuristics.html#TravelingSalesmanHeuristics.nearest_neighbor",
    "page": "Heuristics",
    "title": "TravelingSalesmanHeuristics.nearest_neighbor",
    "category": "function",
    "text": "nearest_neighbor(distmat)\n\nApproximately solve a TSP using the nearest neighbor heuristic. distmat is a square real matrix  where distmat[i,j] represents the distance from city i to city j. The matrix needn\'t be symmetric and can contain negative values. Return a tuple (path, pathcost).\n\nOptional keyword arguments:\n\nfirstcity::Int: specifies the city to begin the path on. Not specifying a value corresponds   to random selection. \nclosepath::Bool = true: whether to include the arc from the last city visited back to the   first city in cost calculations. If true, the first city appears first and last in the path.\ndo2opt::Bool = true: whether to refine the path found by 2-opt switches (corresponds to    removing path crossings in the planar Euclidean case).\n\n\n\n"
},

{
    "location": "heuristics.html#TravelingSalesmanHeuristics.farthest_insertion",
    "page": "Heuristics",
    "title": "TravelingSalesmanHeuristics.farthest_insertion",
    "category": "function",
    "text": "farthest_insertion(distmat; ...)\n\nGenerate a TSP path using the farthest insertion strategy. distmat must be a square real matrix. Return a tuple (path, cost).\n\nOptional arguments:\n\nfirstCity::Int: specifies the city to begin the path on. Not specifying a value corresponds   to random selection.\ndo2opt::Bool = true: whether to improve the path by 2-opt swaps.\n\n\n\n"
},

{
    "location": "heuristics.html#TravelingSalesmanHeuristics.cheapest_insertion",
    "page": "Heuristics",
    "title": "TravelingSalesmanHeuristics.cheapest_insertion",
    "category": "function",
    "text": "cheapest_insertion(distmat::Matrix, initpath::AbstractArray{Int})\n\nGiven a distance matrix and an initial path, complete the tour by repeatedly doing the cheapest  insertion. Return a tuple (path, cost). The initial path must have length at least 2, but can be simply [i, i] for some city index i which corresponds to starting with a loop at city i.\n\nnote: Note\nInsertions are always in the interior of the current path so this heuristic can also be used for non-closed TSP paths.\n\nCurrently the implementation is a naive n^3 algorithm.\n\n\n\ncheapest_insertion(distmat; ...)\n\nComplete a tour using cheapest insertion with a single-city loop as the initial path. Return a tuple (path, cost).\n\nOptional keyword arguments:\n\nfirstCity::Int: specifies the city to begin the path on. Not specifying a value corresponds   to random selection.\ndo2opt::Bool = true: whether to improve the path found by 2-opt swaps.\n\n\n\n"
},

{
    "location": "heuristics.html#Path-generation-heuristics-1",
    "page": "Heuristics",
    "title": "Path generation heuristics",
    "category": "section",
    "text": "nearest_neighborfarthest_insertioncheapest_insertion"
},

{
    "location": "heuristics.html#TravelingSalesmanHeuristics.two_opt",
    "page": "Heuristics",
    "title": "TravelingSalesmanHeuristics.two_opt",
    "category": "function",
    "text": "two_opt(distmat, path)\n\nImprove path by doing 2-opt switches (i.e. reversing part of the path) until doing so no longer reduces the cost. Return a tuple (improved_path, improved_cost).\n\nOn large problem instances this heuristic can be slow, but it is highly recommended on small and medium problem instances.\n\nSee also simulated_annealing for another path generation heuristic.\n\n\n\n"
},

{
    "location": "heuristics.html#TravelingSalesmanHeuristics.simulated_annealing",
    "page": "Heuristics",
    "title": "TravelingSalesmanHeuristics.simulated_annealing",
    "category": "function",
    "text": "simulated_annealing(distmat; ...)\n\nUse a simulated annealing strategy to return a closed tour. The temperature decays exponentially from init_temp to final_temp. Return a tuple (path, cost).\n\nOptional keyword arguments:\n\nsteps::Int = 50n^2: number of steps to take; defaults to 50n^2 where n is number of cities\nnum_starts::Int = 1: number of times to run the simulated annealing algorithm, each time   starting with a random path, or init_path if non-null. Defaults to 1.\ninit_temp::Real = exp(8): initial temperature which controls initial chance of accepting an\n\ninferior tour.\n\nfinal_temp::Real = exp(-6.5) final temperature which controls final chance of accepting an   inferior tour; lower values roughly correspond to a longer period of 2-opt.\ninit_path::Nullable{vector{Int}} = Nullable{Vector{Int}}(): path to start the annealing from.   A Nullable{Vector{Int}}. An empty Nullable corresponds to picking a random path; if the    Nullable contains a value then this path will be used. Defaults to a random path.\n\n\n\n"
},

{
    "location": "heuristics.html#Path-refinement-heuristics-1",
    "page": "Heuristics",
    "title": "Path refinement heuristics",
    "category": "section",
    "text": "two_optsimulated_annealing"
},

{
    "location": "heuristics.html#TravelingSalesmanHeuristics.repetitive_heuristic",
    "page": "Heuristics",
    "title": "TravelingSalesmanHeuristics.repetitive_heuristic",
    "category": "function",
    "text": "repetitive_heuristic(distmat::Matrix, heuristic::Function, repetitive_kw::Symbol; keywords...)\n\nFor each i in 1:n, run heuristic with keyword repetitive_kw set to i. Return the tuple (bestpath, bestcost). By default, repetitive_kw is :firstcity, which is appropriate for the farthest_insertion, cheapest_insertion, and nearest_neighbor heuristics. \n\nAny keywords passed to repetitive_heuristic are passed along to each call of heuristic. For example, repetitive_heuristic(dm, nearest_neighbor; do2opt = true) will perform 2-opt for each of the n nearest neighbor paths.\n\nnote: Note\nThe repetitive heuristic calls are parallelized with threads. For optimum speed make sure Julia is running with multiple threads.\n\n\n\n"
},

{
    "location": "heuristics.html#Repetitive-heuristics-1",
    "page": "Heuristics",
    "title": "Repetitive heuristics",
    "category": "section",
    "text": "Many of the heuristics in this package require some starting state. For example, the nearest neighbor heuristic begins at a first city and then iteratively continues to whichever unvisited city is closest to the current city. Therefore, running the heuristic with different choices for the first city may produce different final paths. At the cost of increased computation time, a better path can often be found by starting the heuristic method at each city. The convenience method repetitive_heuristic is provided to help with this use case:repetitive_heuristic"
},

{
    "location": "heuristics.html#TravelingSalesmanHeuristics.lowerbound",
    "page": "Heuristics",
    "title": "TravelingSalesmanHeuristics.lowerbound",
    "category": "function",
    "text": "lowerbound(distmat)\n\nLower bound the cost of the optimal TSP tour. At present, the bounds considered are a simple bound based on the minimum cost of entering and exiting each city and a slightly better bound inspired by the Held-Karp bounds; note that the implementation here is simpler and less tight than proper HK bounds.\n\nThe Held-Karp-inspired bound requires computing many spanning trees. For a faster but typically looser bound, use TravelingSalesmanHeuristics.vertwise_bound(distmat).\n\nnote: Note\nThe spanning tree bounds are only correct on symmetric problem instances and will not be used if the passed distmat is not symmetric. If you wish to use these bounds anyway, (e.g. for near-symmetric instances), use TravelingSalesmanHeuristics.hkinspired_bound.\n\n\n\n"
},

{
    "location": "heuristics.html#Lower-bounds-1",
    "page": "Heuristics",
    "title": "Lower bounds",
    "category": "section",
    "text": "A simple lower bound on the cost of the optimal tour is provided. This bound uses no problem-specific structure; if you know some details of your problem instance, you can probably find a tighter bound.lowerbound"
},

{
    "location": "examples.html#",
    "page": "Examples",
    "title": "Examples",
    "category": "page",
    "text": "This page gives some examples of using TravelingSalesmanHeuristics. For convenience and so we can easily visualize the problems, we\'ll use planar Euclidean instances generated as follows:function generate_instance(n)\n	srand(47)\n	pts = rand(2, n)\n	distmat = [norm(pts[:,i] - pts[:,j]) for i in 1:n, j in 1:n]\n	return pts, distmat\nendIn this function and throughout the examples, I routinely reseed the global random number generator (with value 47, which is a great number) so that (hopefully) the examples can be reproduced, at least if you\'re using the same Julia version.Some handy visualization functions:using Gadfly\nplot_instance(pts) = plot(x = pts[1,:], y = pts[2,:], Geom.point, Guide.xlabel(nothing), Guide.ylabel(nothing))\nfunction plot_solution(pts, path, extras = [])\n	ptspath = pts[:,path]\n	plot(x = ptspath[1,:], y = ptspath[2,:], Geom.point, Geom.path, Guide.xlabel(nothing), Guide.ylabel(nothing), extras...)\nend"
},

{
    "location": "examples.html#Basic-usage-1",
    "page": "Examples",
    "title": "Basic usage",
    "category": "section",
    "text": "First, generate and plot a small instance:pts, distmat = generate_instance(20)\nplot_instance(pts)(Image: small instance)A quick solution (run it twice to avoid measuring precompilation):srand(47)\n@time path, cost = solve_tsp(distmat; quality_factor = 5)\n      0.000050 seconds (34 allocations: 3.797 KiB)\n    ([4, 19, 17, 14, 5, 1, 20, 9, 16, 2  …  6, 10, 15, 11, 18, 8, 12, 13, 3, 4], 3.8300484331007696)\nplot_solution(pts, path)(Image: small instance solved)It looks like we\'ve found the optimum path, and a higher quality_factor doens\'t give a better objective:srand(47)\n@time path, cost = solve_tsp(distmat; quality_factor = 80)\n      0.006352 seconds (92.43 k allocations: 1.551 MiB)\n    ([2, 16, 9, 20, 1, 5, 14, 17, 19, 4  …  13, 12, 8, 18, 11, 15, 10, 6, 7, 2], 3.830048433100769)On a bigger instance, the quality_factor makes more of a difference:pts, distmat = generate_instance(200)\n@time path, cost = solve_tsp(distmat; quality_factor = 5)\n      0.008352 seconds (34 allocations: 21.031 KiB)\n    ([53, 93, 60, 29, 159, 135, 187, 8, 127, 178  …  11, 10, 154, 59, 80, 6, 108, 188, 57, 53], 10.942110669021305)\n@time path, cost = solve_tsp(distmat; quality_factor = 80)\n      2.066067 seconds (9.00 M allocations: 177.469 MiB, 2.61% gc time)\n    ([20, 27, 76, 23, 92, 146, 161, 194, 152, 171  …  66, 36, 147, 124, 32, 70, 34, 120, 47, 20], 10.552544594904079)\nplot_solution(pts, path)(Image: big instance solved)Note that increasing quality_factor greatly increases the runtime but only slightly improves the objective. This pattern is common."
},

{
    "location": "examples.html#Using-a-specific-heuristic-1",
    "page": "Examples",
    "title": "Using a specific heuristic",
    "category": "section",
    "text": "pts, distmat = generate_instance(100)\npath_nn, cost_nn = nearest_neighbor(distmat; firstcity = 1, do2opt = false) # cost is 9.93\npath_nn2opt, cost_nn2opt = nearest_neighbor(distmat; firstcity = 1, do2opt = true) # cost is 8.15\npath_fi, cost_fi = farthest_insertion(distmat; firstcity = 1, do2opt = false) # cost is 8.12\npath_fi2opt, cost_fi2opt = farthest_insertion(distmat; firstcity = 1, do2opt = true) # cost is 8.06(Image: path nearest neighbor)(Image: path nearest neighbor 2-opt)(Image: path farthest insertion)(Image: path farthest insertion 2-opt)"
},

{
    "location": "examples.html#Simulated-annealing-refinements-1",
    "page": "Examples",
    "title": "Simulated annealing refinements",
    "category": "section",
    "text": "The current simulated annealing implementation is very simple (pull requests most welcome!), but it can nonetheless be useful for path refinement. Here\'s a quick example:pts, distmat = generate_instance(300)\npath_quick, cost_quick = solve_tsp(distmat)\n    ([104, 185, 290, 91, 294, 269, 40, 205, 121, 271  …  156, 237, 97, 288, 137, 63, 257, 168, 14, 104], 13.568672416542647)\npath_sa, cost_sa = simulated_annealing(distmat; init_path = Nullable(path_quick), num_starts = 10)\n    ([104, 14, 168, 257, 63, 137, 46, 101, 44, 193  …  220, 269, 40, 121, 205, 294, 91, 290, 185, 104], 13.298439981448235)"
},

{
    "location": "examples.html#Lower-bounds-1",
    "page": "Examples",
    "title": "Lower bounds",
    "category": "section",
    "text": "In the previous section, we generated a 300 point TSP in the unit square. Is the above solution with cost about 13.3 any good? We can get a rough lower bound:lowerbound(distmat)\n    11.5998918075456Let\'s see where that bound came from:TravelingSalesmanHeuristics.vertwise_bound(distmat)\n    8.666013688087942\nTravelingSalesmanHeuristics.hkinspired_bound(distmat)\n    11.5998918075456Because our problem is symmetric, the latter bound based on spanning trees applies, and this bound is typically tighter.If we use an integer program to solve the TSP to certified optimality (beyond the scope of this package), we find that the optimal solution has cost about 12.82. So the final path found by simulated annealing is about 3.7% worse than the optimal path, and the lower bound reported is about 9.5% lower than the optimal cost. These values are quite typical for mid-sized Euclidean instances.  (Image: 300 point optimal path)(Image: 300 point simulated annealing path)"
},

]}
