using TravelingSalesmanHeuristics
using Test
using Random
using LinearAlgebra

###
# helpers
###

# generate a Euclidean distance matrix for n points in the unit square
function generate_planar_distmat(n)
	pts = rand(2, n)
	dm = [norm(pts[:,i] - pts[:,j]) for i in 1:n, j in 1:n]
end

# test that a path is acceptable:
# - at most one city appears twice, and if so must be first and last
# - all values 1:n are present where n is the maximum city index, and no other values
function testpathvalidity(path, iscycle)
	if iscycle
		@test path[1] == path[end]
	end
	n = iscycle ? length(path) - 1 : length(path)
	@test sort(unique(path)) == collect(1:n)
end

# tests that a path-cost pair is consistent with the distance matrix
# basically a reimplementation of `pathcost`, but hey...less likely to double a mistake?
function testpathcost(path, cost, dm)
	c = zero(eltype(dm))
	for i in 1:(length(path) - 1)
		c += dm[path[i], path[i+1]]
	end
	@test isapprox(c, cost)
end

###
# main tests
###

function test_nearest_neighbor()
	distmats = [generate_planar_distmat(10), generate_planar_distmat(2)]
	
	for dm in distmats
		n = size(dm, 1)
		randstartcity = rand(1:n)
		# standard
		path, cost = nearest_neighbor(dm)
		@test cost > 0
		testpathvalidity(path, true)
		# repetitive
		path, cost = repetitive_heuristic(dm, nearest_neighbor)
		@test cost > 0
		testpathvalidity(path, true)
		# no loop, 2 opt
		path, cost = nearest_neighbor(dm, closepath = false)
		@test cost > 0
		testpathvalidity(path, false)
		# no loop, no 2 opt
		path, cost = nearest_neighbor(dm, closepath = false, do2opt = false)
		@test cost > 0
		testpathvalidity(path, false)
		# fixed start, no loop
		path, cost = nearest_neighbor(dm, closepath = false, firstcity = randstartcity)
		@test cost > 0
		testpathvalidity(path, false)
	end
	
	dm_bad = rand(3,2)
	@test_throws ErrorException nearest_neighbor(dm_bad)
end

function test_cheapest_insertion()
	# default random start
	dm = generate_planar_distmat(8)
	path, cost = cheapest_insertion(dm)
	@test cost > 0
	testpathvalidity(path, true) # should be a closed path
	# repetitive start
	path, cost = repetitive_heuristic(dm, cheapest_insertion)
	@test cost > 0
	testpathvalidity(path, true)
	
	# bad input
	dmbad = rand(2,3)
	@test_throws ErrorException cheapest_insertion(dmbad)
end

function test_farthest_insertion()
	# standard symmetric case
	dm = generate_planar_distmat(8)
	path, cost = farthest_insertion(dm)
	testpathvalidity(path, true)
	testpathcost(path, cost, dm)
	# invalid argument
	@test_throws ErrorException farthest_insertion(dm; firstcity = 0)
	# asymmetric matrix
	dm = rand(20, 20)
	path, cost = farthest_insertion(dm; firstcity = 1, do2opt = true)
	testpathvalidity(path, true)
	testpathcost(path, cost, dm)
end

function test_simulated_annealing()
	dm = generate_planar_distmat(14)
	# single start
	path, cost = simulated_annealing(dm)
	@test cost > 0
	testpathvalidity(path, true) # closed path
	# multi-start
	dm = generate_planar_distmat(8)
	path, cost = simulated_annealing(dm, num_starts = 3)
	@test cost > 0
	testpathvalidity(path, true) # also closed
	# given init path
	init_path = collect(1:8)
	push!(init_path, 1)
	reverse!(init_path, 2, 6)
	path, cost = simulated_annealing(dm; init_path = init_path)
	@test cost > lowerbound(dm)
	testpathvalidity(path, true) # still closed
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

function test_solve_tsp()
	dm = rand(10,10)
	quality_factors = [-1, 0, 1.1, 35, 101]
	for qf in quality_factors
		path, cost = solve_tsp(dm; quality_factor = qf)
		testpathvalidity(path, true)
	end
end

function test_two_opt()
	n = 50
	dm = generate_planar_distmat(n)
	path = collect(1:n)
	path_2opt, _ = two_opt(dm, path)
	testpathvalidity(path_2opt, false)
	# shouldn't affect endpoints
	@test path_2opt[1] == 1
	@test path_2opt[end] == n
	cycle = vcat(path, 1)
	cycle_2opt, _ = two_opt(dm, cycle)
	testpathvalidity(cycle_2opt, true)
	# same endpoints
	@test cycle_2opt[1] == 1 == cycle_2opt[n+1]
end

function test_atypical_types()
	# rational distance matrix
	dm = [rationalize(rand(); tol = .01) for i in 1:10, j in 1:10]
	initpath = 1:2:9 # not a Vector, but <:AbstractVector{<:Int}
	p, c = cheapest_insertion(dm, initpath)
	testpathvalidity(p, false)
end

###
# run
###
println("Hello tester")
Random.seed!(47)
test_nearest_neighbor()
test_cheapest_insertion()
test_farthest_insertion()
test_simulated_annealing()
test_bounds()
test_path_costs()
test_solve_tsp()
test_two_opt()
test_atypical_types()
println("Done testing.")
