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
function visPlanarTSP(n = 10, heuristic = nearestNeighbor; extraArgs...)
	pts = rand(2, n)
	distMat = pairwise(Euclidean(), pts, pts)
	path, _ = heuristic(distMat; extraArgs...)
	visTSP(pts, path)
end

# compare some heuristics
function compareHeuristics(n = 20)
	pts = rand(2, n)
	dm = pairwise(Euclidean(), pts, pts)
	singlenn_no2opt = nearestNeighbor(dm, do2opt = false)
	println("Single start nearest neighbor without 2-opt has cost $(singlenn_no2opt[2])")
	singlenn_2opt = nearestNeighbor(dm, do2opt = true)
	println("Single start nearest neighbor with 2-opt has cost $(singlenn_2opt[2])")
	repnn_no2opt = nearestNeighbor(dm, repetitive = true, do2opt = false)
	println("Multi start nearest neighbor without 2-opt has cost $(repnn_no2opt[2])")
	repnn_2opt = nearestNeighbor(dm, repetitive = true, do2opt = true)
	println("Multi start nearest neighbor with 2-opt has cost $(repnn_2opt[2])")
	cheapinsert_no2opt = cheapest_insertion(dm)
	println("Cheap insert with no 2-opt has cost $(cheapinsert_no2opt[2])")
	cheapinsert_2opt = twoOpt(dm, cheapinsert_no2opt[1])
	println("Cheap insert with 2-opt has cost $(cheapinsert_2opt[2])")
end
