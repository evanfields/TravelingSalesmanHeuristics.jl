###
# helpers
###

# make sure a passed distance matrix is a square
function check_square(m, msg)
	n = size(m, 1)
	if n != size(m, 2)
		error(msg)
	end
	return n
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

#Cost of inserting city `k` after index `after` in path `path` with costs `distmat`.
function inscost(k::Int, after::Int, path::Vector{Int}, distmat::Matrix)
	return distmat[path[after], k] + 
		  distmat[k, path[after + 1]] -
		  distmat[path[after], path[after + 1]]
end
