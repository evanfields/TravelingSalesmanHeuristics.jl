# This file contains "tests for humans:" functions you might use to reassure
# yourself that the heuristics are working properly or chose a heuristic for your
# particular problem. The functions in this file are not run by Travis and this file
# requires several packages (such as Gadfly) not listed in the REQUIRE.
using Gadfly
using TravelingSalesmanHeuristics

function visPlanarTSP(n = 10; extraArgs...)
	pts = rand(2, n)
	distMat = pairwise(Euclidean(), pts, pts)
	path = nearestNeighbor(distMat; extraArgs...)
	pts = pts[:,path]
	plot(x = pts[1,:], y = pts[2,:], Geom.path, Geom.point)
end