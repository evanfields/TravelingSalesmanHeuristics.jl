module TravelingSalesmanHeuristics
using Graphs

export solve_tsp, lowerbound, nearestNeighbor, cheapest_insertion, twoOpt

"""
.. solve_tsp(distmat) ..

One-line interface to approximately solving a TSP by specifying a distance matrix.
This method provides fairly quick solutions but no extra control. For more fine-grained
control over the heuristics used, try nearestNeighbor or cheapest_insertion.
"""
function solve_tsp{T<:Real}(distmat::Matrix{T})
	p1, c1 = nearestNeighbor(distmat)
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
function nearestNeighbor{T<:Real}(distmat::Matrix{T};
							   firstcity::Nullable{Int} = Nullable{Int}(),
							   repetitive = false,
							   closepath = true,
							   do2opt = true)
	# must have a square matrix 
	if size(distmat, 1) != size(distmat, 2)
		error("Must pass a square distance matrix to nearestNeighbor")
	end
	numCities = size(distmat, 1)
	
	# if repetitive, we do all possible cities, and pick the best
	if repetitive
		function nnHelper(i)
			nearestNeighbor(distmat,
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
		path, _ = twoOpt(distmat, path)
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
	if size(distmat, 1) != size(distmat, 2)
		error("Distance matrix passed to cheapest_insertion must be square.")
	end
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
		path, cost = twoOpt(distmat, path)
	end
	
	return path, cost
end

###
# helpers
###

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

# helper to get min spanning trees
# returns a (n-1) long Vector of Tuple{Int, Int} where each tuple is an edge in the MST
# and the total weight of the tree
function minspantree(distmat)
	if size(distmat, 1) != size(distmat, 2)
		error("Distance matrix passed to minspantree must be square.")
	end
	n = size(distmat, 1)
	numEdge = convert(Int, n * (n-1)) # not / 2 since directed graph
	
	# construct graph and list of edge weights
	g = simple_complete_graph(n)
	eWeights = zeros(numEdge)
	
	for i in eachindex(edges(g))
		e = edges(g)[i]
		eWeights[i] = distmat[source(e), target(e)]
	end
	
	(treeEdges, treeWeights) = kruskal_minimum_spantree(g, eWeights)
	
	return (map(e -> (source(e), target(e)), treeEdges),
		    sum(treeWeights))
end
	
###
# path improvement heuristics
###

"perform 2-opt reversals until doing so does not improve the path cost"
function twoOpt{T<:Real}(distmat::Matrix{T}, path::Vector{Int})
	# size checks
	n = length(path)
	if size(distmat, 1) != size(distmat, 2)
		error("Distance matrix passed to twoOpt must be square.")
	end
	
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

### 
# bounds
###

# I implement several simple but super loose bounds
# These only apply to closed tours

# the cost of a tour must be >= the sum over all vertices of
# the cost of the cheapest edge leaving that vertex
# likewise for the cheapest edge entering that vertex
# since we must go to and leave each vertex
function vertwise_bound(distmat)
	# the simple code below would tend to pick out the 0 costs on the diagonal
	# so make a doctored copy of the distance matrix with high costs on the diagonal
	m = maximum(distmat)
	distmat_nodiag = distmat + m * eye(distmat)
	leaving = sum(minimum(distmat_nodiag, 2))
	entering = sum(minimum(distmat_nodiag, 1))
	return maximum([leaving, entering])
end

# a simplified/looser version of Held-Karp bounds
# any tour is a spanning tree on (n-1) verts plus two edges
# from the left out vert
# so the maximum over all verts (as the left out vert) of 
# MST cost on remaining vertices plus 2 cheapest edges from
# the left out vert is a lower bound
function hkinspired_bound(distmat)
	n = size(distmat, 1)
	if size(distmat, 2) != n
		error("Must pass square distance matrix to hkinspired_bound")
	end
	function del_vert(v)
		keep = [1:(v-1) ; (v+1):n]
		return distmat[keep, keep]
	end
	
	function cost_leave_out(v)
		dmprime = del_vert(v)
		_, c = minspantree(dmprime)
		c += minimum(distmat[v,:])
		c += minimum(distmat[:,v])
		return c
	end
	
	return maximum(map(cost_leave_out, 1:n))
end

# best lower bound we have
"""
Lower bound the cost of the optimal TSP tour. At present, the bounds considered
are a simple bound based on the minimum cost of entering and exiting each city and
a slightly better bound inspired by the Held-Karp bounds; note that the implementation
here is simpler and less tight than proper HK bounds.
"""
function lowerbound(distmat)
	return maximum([
			vertwise_bound(distmat),
			hkinspired_bound(distmat)
			])
end

end # module
