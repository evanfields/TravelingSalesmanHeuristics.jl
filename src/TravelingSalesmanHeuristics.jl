module TravelingSalesmanHeuristics
using Distances

export nearestNeighbor, twoOpt

# Approximately solve a TSP using the nearest neighbor heuristic. You must pass a square matrix
# distMat where distMat[i,j] represents the distance from city i to city j. The matrix needn't be
# symmetric and possibly could contain negative values, though nonpositive values have not been tested.
# Optional arguments:
# firstCity: specifiese the city to begin the path on. An empty Nullable corresponds to random selection. 
#	this argument is ignored if repetitive = true
# repetitive: boolean for whether to try starting from all possible cities, keeping the best
# closepath: boolean for whether to include the arc from the last city visited back to the first city in
#	cost calculations. If true, the first city appears first and last in the path
# do2opt: whether to refine the path found by 2-opt switches (corresponds to removing path crossings in
#	the planar Euclidean case)
# returns a tuple (path, pathCost) where path is a Vector{Int} corresponding to the order of cities visited
function nearestNeighbor{T<:Real}(distMat::Matrix{T};
							   firstcity::Nullable{Int} = Nullable{Int}(),
							   repetitive = false,
							   closepath = true,
							   do2opt = true)
	# must have a square matrix 
	if size(distMat, 1) != size(distMat, 2)
		error("Must pass a square distance matrix to nearestNeighbor")
	end
	numCities = size(distMat, 1)
	
	# if repetitive, we do all possible cities, and pick the best
	if repetitive
		function nnHelper(i)
			nearestNeighbor(distMat,
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
		dists = distMat[curCity, citiesToVisit]
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
		path = twoOpt(distMat, path)
	end
	
	return (path, pathCost(distMat, path))
end

function pathCost(distMat, path)
	cost = 0
	for i in 1:(length(path) - 1)
		cost += distMat[path[i], path[i+1]]
	end
	return cost
end



function twoOpt{T<:Real}(distMat::Matrix{T}, path::Vector{Int})
	# size checks
	n = length(path)
	if size(distMat, 1) != size(distMat, 2)
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
	curCost = pathCost(distMat, path)
	while prevCost > pathCost(distMat, path)
		prevCost = curCost
		# we can't change the first 
		for i in switchLow:(n-1)
			for j in (i+1):switchHigh
				altPath = reverse(path, i, j)
				altCost = pathCost(distMat, altPath)
				if altCost < curCost
					path = altPath
					curCost = altCost
				end
			end
		end
	end
	
	return path
end


end # module
