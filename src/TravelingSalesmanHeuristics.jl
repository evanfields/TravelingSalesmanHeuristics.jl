module TravelingSalesmanHeuristics

using Compat

include("simulated_annealing.jl")
include("lowerbounds.jl")

export solve_tsp, lowerbound, nearest_neighbor, cheapest_insertion, simulated_annealing, two_opt

"""
.. solve_tsp(distmat) ..

One-line interface to approximately solving a TSP by specifying a distance matrix.
This method provides fairly quick solutions but no extra control. For more fine-grained
control over the heuristics used, try nearest_neighbor or cheapest_insertion.
"""
function solve_tsp{T<:Real}(distmat::Matrix{T})
	p1, c1 = nearest_neighbor(distmat)
	p2, c2 = cheapest_insertion(distmat)
	if c1 < c2
		return p1, c1
	else
		return p2, c2
	end
end

###
# path generation heuristics
###

"""
Approximately solve a TSP using the nearest neighbor heuristic. You must pass a square matrix
distmat where distmat[i,j] represents the distance from city i to city j. The matrix needn't be
symmetric and possibly could contain negative values, though nonpositive values have not been tested.


Optional arguments:

firstCity: specifies the city to begin the path on. An empty Nullable corresponds to random selection. 
	This argument is ignored if repetitive = true. Defaults to an empty Nullable{Int}
	
repetitive: boolean for whether to try starting from all possible cities, keeping the best. Defaults to false.

closepath: boolean for whether to include the arc from the last city visited back to the first city in
	cost calculations. If true, the first city appears first and last in the path. Defaults to true.
	
do2opt: whether to refine the path found by 2-opt switches (corresponds to removing path crossings in
	the planar Euclidean case). Defaults to true.
	
returns a tuple (path, pathcost) where path is a Vector{Int} corresponding to the order of cities visited
"""
function nearest_neighbor{T<:Real}(distmat::Matrix{T};
							   firstcity::Nullable{Int} = Nullable{Int}(),
							   repetitive = false,
							   closepath = true,
							   do2opt = true)
	# must have a square matrix 
	check_square(distmat, "Must pass a square distance matrix to nearest_neighbor")
	
	numCities = size(distmat, 1)
	
	# if repetitive, we do all possible cities, and pick the best
	if repetitive
		function nnHelper(i)
			nearest_neighbor(distmat,
						  firstcity = Nullable(i),
						  closepath = closepath,
						  do2opt = do2opt,
						  repetitive = false)
		end
		# do nn for each startin city
		results = map(nnHelper, collect(1:numCities))
		# pick out lowest cost
		_, bestInd = findmin(map(res -> res[2], results))
		return results[bestInd]
	end
	
	# if not repetitive, we actually perform the heuristic for one starting city
	
	# put first city on path
	path = Vector{Int}()
	if isnull(firstcity)
		firstcity = rand(1:numCities)
	else
		firstcity = get(firstcity)
	end
	push!(path, firstcity)
	
	# cities to visit
	citiesToVisit = collect(1:(firstcity - 1))
	append!(citiesToVisit, collect((firstcity + 1):numCities))
	
	# nearest neighbor loop
	while !isempty(citiesToVisit)
		curCity = path[end]
		dists = distmat[curCity, citiesToVisit]
		_, nextInd = findmin(dists)
		nextCity = citiesToVisit[nextInd]
		push!(path, nextCity)
		deleteat!(citiesToVisit, nextInd)
	end
	
	# complete cycle? (duplicates first city)
	if closepath
		push!(path, firstcity)
	end
	
	# do swaps?
	if do2opt
		path, _ = two_opt(distmat, path)
	end
	
	return (path, pathcost(distmat, path))
end

"""
.. cheapest_insertion(distmat, initpath) ..


Given a distance matrix and an initial path, complete the tour by
repeatedly doing the cheapest insertion. The initial path must have length at least 2, but can be
simply [i, i] for some city index i which corresponds to starting with a self-loop at city i.
Insertions are always in the interior of the current path so this heuristic can also be used for
non-closed TSP paths.
Currently the implementation is a naive n^3 algorithm.
"""
function cheapest_insertion{T<:Real}(distmat::Matrix{T}, initpath::Vector{Int})
	check_square(distmat, "Distance matrix passed to cheapest_insertion must be square.")
	
	n = size(distmat, 1)
	path = copy(initpath)
	
	# collect cities to visited
	visitus = setdiff(collect(1:n), initpath)
		
	# helper for insertion cost
	# tour cost change for inserting node k after the node at index after in the path
	function inscost(k, after)
		return distmat[path[after], k] + 
			  distmat[k, path[after + 1]] -
			  distmat[path[after], path[after + 1]]
	end
	
	while !isempty(visitus)
		bestCost = Inf
		bestInsertion = (-1, -1)
		for k in visitus
			for after in 1:(length(path) - 1) # can't insert after end of path
				c = inscost(k, after)
				if c < bestCost
					bestCost = c
					bestInsertion = (k, after)
				end
			end
		end
		# bestInsertion now holds (k, after)
		# insert into path, remove from to-do list
		k, after = bestInsertion
		insert!(path, after + 1, k)
		visitus = setdiff(visitus, k)
	end
	
	return (path, pathcost(distmat, path))
end
"""
.. cheapest_insertion(distmat; ...) ..


Cheapest insertion with a self-loop as the initial path.
distmat must be a square real matrix. Non-symmetric distance matrices should work. Negative
distances have not been tested but may also work.

Optional arguments:

firstcity: Specifies which city should have a self loop as the initial path. Nullable(i) for 
city i or an empty Nullable{Int} for random selection. This argument is ignored if
repetitive = true. Defaults to random selection.

repetitive: boolean for whether to try starting from all possible cities, keeping the best. Defaults to false.

do2opt: boolean for whether to improve the paths found by 2-opt swaps. Defaults to true.
"""
function cheapest_insertion{T<:Real}(distmat::Matrix{T};
								 firstcity::Nullable{Int} = Nullable{Int}(),
							     repetitive::Bool = false,
								 do2opt::Bool = true)
	#infer size
	n = size(distmat, 1)

	# if repetitive, we do all possible cities, and pick the best
	if repetitive
		function ciHelper(i)
			cheapest_insertion(distmat,
						  firstcity = Nullable(i),
						  do2opt = do2opt,
						  repetitive = false)
		end
		# do cheapest insertion for each starting city
		results = map(ciHelper, collect(1:n))
		# pick out lowest cost
		_, bestInd = findmin(map(res -> res[2], results))
		return results[bestInd]
	end
	
	# okay, we're not repetitive. Do we pick first city at random?
	firstcity = isnull(firstcity) ? rand(1:n) : get(firstcity)
	path, cost = cheapest_insertion(distmat, [firstcity, firstcity])
	
	# user may have asked for 2-opt refinement
	if do2opt
		path, cost = two_opt(distmat, path)
	end
	
	return path, cost
end

###
# helpers
###

# make sure a passed distance matrix is a square
function check_square(m, msg)
	if size(m, 1) != size(m, 2)
		error(msg)
	end
end

# helper for readable one-line path costs
# optionally specify the bounds for the subpath we want the cost of
# defaults to the whole path
# but when calculating reversed path costs can help to have subpath costs
function pathcost{T<:Real}(distmat::Matrix{T}, path::Vector{Int}, lb::Int = 1, ub::Int = length(path))
	cost = zero(T)
	for i in lb:(ub - 1)
		@inbounds cost += distmat[path[i], path[i+1]]
	end
	return cost
end
# calculate the cost of reversing part of a path
# cost of walking along the entire path specified but reversing the sequence from revLow to revHigh, inclusive
function pathcost_rev{T<:Real}(distmat::Matrix{T}, path::Vector{Int}, revLow::Int, revHigh::Int)
	cost = zero(T)
	# if there's an initial unreversed section
	if revLow > 1
		for i in 1:(revLow - 2)
			@inbounds cost += distmat[path[i], path[i+1]]
		end
		# from end of unreversed section to beginning of reversed section
		@inbounds cost += distmat[path[revLow - 1], path[revHigh]]
	end
	# main reverse section
	for i in revHigh:-1:(revLow + 1)
		@inbounds cost += distmat[path[i], path[i-1]]
	end
	# if there's an unreversed section after the reversed bit
	n = length(path)
	if revHigh < length(path)
		# from end of reversed section back to regular
		@inbounds cost += distmat[path[revLow], path[revHigh + 1]]
		for i in (revHigh + 1):(n-1)
			@inbounds cost += distmat[path[i], path[i+1]]
		end
	end
	return cost
end
	
###
# path improvement heuristics
###

"perform 2-opt reversals until doing so does not improve the path cost

First argument is the distance matrix, second is the path to be improved."
function two_opt{T<:Real}(distmat::Matrix{T}, path::Vector{Int})
	# size checks
	n = length(path)
	if size(distmat, 1) != size(distmat, 2)
		error("Distance matrix passed to two_opt must be square.")
	end
	
	# don't modify input
	path = copy(path)
	
	# main loop
	# check every possible switch until no 2-swaps reduce objective
	# if the path passed in is a loop (first/last nodes are the same)
	# then we must keep these the endpoints of the path the same
	# ie just keep it a loop, and therefore it doesn't matter which node is at the end
	# if the path is not a cycle, we can do any reversing we like
	isCycle = path[1] == path[end]
	switchLow = isCycle ? 2 : 1
	switchHigh = isCycle ? n - 1 : n
	prevCost = Inf
	curCost = pathcost(distmat, path)
	while prevCost > pathcost(distmat, path)
		prevCost = curCost
		# we can't change the first 
		for i in switchLow:(switchHigh-1)
			for j in (i+1):switchHigh
				altCost = pathcost_rev(distmat, path, i, j)
				if altCost < curCost
					curCost = altCost
					reverse!(path, i, j)
				end
			end
		end
	end
	return path, pathcost(distmat, path)
end

end # module
