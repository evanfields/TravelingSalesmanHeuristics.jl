# This file contains "tests for humans:" functions you might use to reassure
# yourself that the heuristics are working properly or chose a heuristic for your
# particular problem. The functions in this file are not run by Travis and this file
# requires several packages (such as Gadfly) not listed in the REQUIRE.
using Gadfly
using TravelingSalesmanHeuristics
using Distances

# use Gadfly to plot a TSP visualization
# pts must be a 2 x n matrix and path the vector of column indices
function visTSP(pts, path)
	pts = pts[:,path]
	plot(x = pts[1,:], y = pts[2,:], Geom.path, Geom.point)
end
# visualize a planar TSP in the unit square
# specify number of points and solution method
function visPlanarTSP(n = 10, heuristic = nearest_neighbor; extraArgs...)
	pts = rand(2, n)
	distMat = pairwise(Euclidean(), pts, pts)
	path, _ = heuristic(distMat; extraArgs...)
	visTSP(pts, path)
end

# compare some heuristics
function compareHeuristics(n = 20)
	pts = rand(2, n)
	dm = pairwise(Euclidean(), pts, pts)
	println("Simple lower bound: $(lowerbound(dm))")
	singlenn_no2opt = nearest_neighbor(dm, do2opt = false)
	println("Single start nearest neighbor without 2-opt has cost $(singlenn_no2opt[2])")
	singlenn_2opt = nearest_neighbor(dm, do2opt = true)
	println("Single start nearest neighbor with 2-opt has cost $(singlenn_2opt[2])")
	repnn_no2opt = repetitive_heuristic(dm, nearest_neighbor, do2opt = false)
	println("Multi start nearest neighbor without 2-opt has cost $(repnn_no2opt[2])")
	repnn_2opt = repetitive_heuristic(dm, nearest_neighbor, do2opt = true)
	println("Multi start nearest neighbor with 2-opt has cost $(repnn_2opt[2])")
	singleci_no2opt = cheapest_insertion(dm, do2opt = false)
	println("Single start cheapest insert without 2-opt has cost $(singleci_no2opt[2])")
	singleci_2opt = cheapest_insertion(dm, do2opt = true)
	println("Single start cheapest insert with 2-opt has cost $(singleci_2opt[2])")
	multici_no2opt = repetitive_heuristic(dm, cheapest_insertion, do2opt = false)
	println("Multi start cheapest insert without 2-opt has cost $(multici_no2opt[2])")
	multici_2opt = repetitive_heuristic(dm, cheapest_insertion, do2opt = true)
	println("Multi start cheapest insert with 2-opt has cost $(multici_2opt[2])")
	simanneal = simulated_annealing(dm)
	println("Simulated annealing with default arguments has cost $(simanneal[2])")
end
