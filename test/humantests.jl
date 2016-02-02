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