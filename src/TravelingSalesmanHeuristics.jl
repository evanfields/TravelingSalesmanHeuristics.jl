module TravelingSalesmanHeuristics
using Distances

export nearestNeighbor

function nearestNeighbor{T<:Real}(distMat::Matrix{T};
							   firstcity::Nullable{Int} = Nullable{Int}(),
							   closepath = true,
							   do2opt = true)
	# must have a square matrix 
	if size(distMat, 1) != size(distMat, 2)
		error("Must pass a square distance matrix to nearestNeighbor")
	end
	numCities = size(distMat, 1)
	
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
	
	return path
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

function visPlanarTSP(n = 10; extraArgs...)
	pts = rand(2, n)
	distMat = pairwise(Euclidean(), pts, pts)
	path = nearestNeighbor(distMat; extraArgs...)
	pts = pts[:,path]
	plot(x = pts[1,:], y = pts[2,:], Geom.path, Geom.point)
end


end # module
