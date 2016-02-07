using TravelingSalesmanHeuristics
using Base.Test
using Distances

###
# helpers
###

# generate a Euclidean distance matrix for n points in the unit square
function generate_planar_distmat(n)
	pts = rand(2, n)
	return pairwise(Euclidean(), pts, pts)
end

# test that a path is acceptable:
# - at most one city appears twice, and if so must be first and last
# - all values 1:n are present where n is the maximum city index, and no other values
function testpathvalidity(path, iscycle)
	if iscycle
		@test path[1] == path[end]
		pop!(path)
	end
	path = sort(path)
	for i in 1:length(path)
		@test path[i] == i
	end
end



###
# main tests
###

function test_nearest_neighbor()
	distmats = cell(2)
	distmats[1] = generate_planar_distmat(10)
	distmats[2] = generate_planar_distmat(2)
	
	for dm in distmats
		n = size(dm, 1)
		randstartcity = rand(1:n)
		# standard
		path, cost = nearestNeighbor(dm)
		@test cost > 0
		testpathvalidity(path, true)
		# repetitive
		path, cost = nearestNeighbor(dm, repetitive = true)
		@test cost > 0
		testpathvalidity(path, true)
		# no loop, 2 opt
		path, cost = nearestNeighbor(dm, closepath = false)
		@test cost > 0
		testpathvalidity(path, false)
		# no loop, no 2 opt
		path, cost = nearestNeighbor(dm, closepath = false, do2opt = false)
		@test cost > 0
		testpathvalidity(path, false)
		# fixed start, no loop
		path, cost = nearestNeighbor(dm, closepath = false, firstcity = Nullable(randstartcity))
		@test cost > 0
		testpathvalidity(path, false)
	end
	
	dm_bad = rand(3,2)
	@test_throws ErrorException nearestNeighbor(dm_bad)
end

function test_cheapest_insertion()
	# default random start
	dm = generate_planar_distmat(8)
	path, cost = cheapest_insertion(dm)
	@test cost > 0
	testpathvalidity(path, true) # should be a closed path
	# repetitive start
	path, cost = cheapest_insertion(dm, repetitive = true)
	@test cost > 0
	testpathvalidity(path, true)
	
	# bad input
	dmbad = rand(2,3)
	@test_throws ErrorException cheapest_insertion(dmbad)
end

function test_bounds()
	dm = generate_planar_distmat(2)
	path, cost = solve_tsp(dm)
	lb = lowerbound(dm)
	@test lb <= cost
	dm = generate_planar_distmat(30)
	path, cost = solve_tsp(dm)
	lb = lowerbound(dm)
	@test lb <= cost
end

function test_path_costs()
	dm = [1 2 3; 4 5 6; 7 8 9]
	p1 = [1, 2, 3, 1]
	@test TravelingSalesmanHeuristics.pathcost(dm, p1) == 2 + 6 + 7
	# various reverse indices to test
	revs = [(1,4), (2,3), (2,4), (3,3)]
	for rev in revs
		path_rev = reverse(p1, rev[1], rev[2])
		@test TravelingSalesmanHeuristics.pathcost(dm, path_rev) == 
			  TravelingSalesmanHeuristics.pathcost_rev(dm, p1, rev[1], rev[2])
	end
end

###
# run
###
srand(47)
test_nearest_neighbor()
test_cheapest_insertion()
test_bounds()
test_path_costs()
println("Done testing.")
