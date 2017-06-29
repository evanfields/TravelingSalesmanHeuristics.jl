module TravelingSalesmanHeuristics

using Compat: view

include("helpers.jl")
include("simulated_annealing.jl")
include("lowerbounds.jl")

export solve_tsp, lowerbound, nearest_neighbor, cheapest_insertion, simulated_annealing, farthest_insertion, two_opt

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

firstCity (Int): specifies the city to begin the path on. Not specifying a value corresponds to random selection. 
	This argument is ignored if repetitive = true.
	
repetitive: boolean for whether to try starting from all possible cities, keeping the best. Defaults to false.

closepath: boolean for whether to include the arc from the last city visited back to the first city in
	cost calculations. If true, the first city appears first and last in the path. Defaults to true.
	
do2opt: whether to refine the path found by 2-opt switches (corresponds to removing path crossings in
	the planar Euclidean case). Defaults to true.
	
returns a tuple (path, pathcost) where path is a Vector{Int} corresponding to the order of cities visited
"""
function nearest_neighbor{T<:Real}(distmat::Matrix{T};
							   firstcity::Union{Int, Nullable{Int}} = rand(1:size(distmat, 1)),
							   repetitive = false,
							   closepath = true,
							   do2opt = true)
	# must have a square matrix 
	numCities = check_square(distmat, "Must pass a square distance matrix to nearest_neighbor")
	
	# for backward compatibility, firstcity can be Int or Nullable{Int}
	# extract an int value
	if isa(firstcity, Int)
		firstcityint = firstcity
	else # Nullable{Int}
		firstcityint = isnull(firstcity) ? rand(1:numCities) : get(firstcity)
	end
	
	# if repetitive, we do all possible cities, and pick the best
	if repetitive
		function nnHelper(i)
			nearest_neighbor(distmat,
						  firstcity = i,
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
	push!(path, firstcityint)
	
	# cities to visit
	citiesToVisit = collect(1:(firstcityint - 1))
	append!(citiesToVisit, collect((firstcityint + 1):numCities))
	
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
		push!(path, firstcityint)
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
	
	while !isempty(visitus)
		bestCost = Inf
		bestInsertion = (-1, -1)
		for k in visitus
			for after in 1:(length(path) - 1) # can't insert after end of path
				c = inscost(k, after, path, distmat)
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

function farthest_insertion{T<:Real}(distmat::Matrix{T}, firstcity::Int = rand(1:size(distmat, 1)))
	n = check_square(distmat, "Must pass square distance matrix to farthest_insertion.")
	if firstcity < 1 || firstcity > n
		error("First city for farthest_insertion must be in [1,..,n]")
	end
	smallval = minimum(distmat) - one(T) # will never be the max
	
	path = Int[firstcity, firstcity]
	sizehint!(path, n)
	dists_to_tour = (distmat[firstcity, :] + distmat[:, firstcity]) / 2
	dists_to_tour[firstcity] = smallval
	
	while length(path) < n + 1
		# city farthest from tour
		_, nextcity = findmax(dists_to_tour)
		
		# find where to add it
		bestcost = inscost(nextcity, 1, path, distmat)
		bestind = 1
		for ind in 2:(length(path) - 1)
			altcost = inscost(nextcity, ind, path, distmat)
			if altcost < bestcost
				bestcost = altcost
				bestind = ind
			end
		end
		# and add the next city at the best spot found
		insert!(path, bestind + 1, nextcity) # +1 since arg to insert! is where nextcity ends up
		
		# update distances to tour
		dists_to_tour[nextcity] = smallval
		for i in 1:n
			c = dists_to_tour[i]
			if c == zero(T) # i already in tour
				continue
			end
			altc = (distmat[i, nextcity] + distmat[nextcity, i]) / 2 # cost i--nextcity
			if altc < c
				@inbounds dists_to_tour[i] = altc
			end
		end
	end
	return path, pathcost(distmat, path)
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
