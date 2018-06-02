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

"""
    legal_circuit(circuit::AbstractArray{<:Integer})

Check that an array of integers is a valid circuit. A valid circuit over `n` locations has
length `n+1`. The first `n` entries are a permutation of `1, ..., n`, and the `(n+1)`-st entry
is equal to the first entry.
"""
function legal_circuit(circuit)
	n = length(circuit) - 1
	return circuit[1] == circuit[end] && sort(circuit[1:(end-1)]) == 1:n
end

"""
    repetitive_heuristic(distmat::Matrix, heuristic::Function, repetitive_kw::Symbol; keywords...)

For each `i` in `1:n`, run `heuristic` with keyword `repetitive_kw` set to `i`. Return the tuple
`(bestpath, bestcost)`. By default, `repetitive_kw` is `:firstcity`, which is appropriate for the
`farthest_insertion`, `cheapest_insertion`, and `nearest_neighbor` heuristics. 

Any keywords passed to `repetitive_heuristic` are passed along to each call of `heuristic`. For
example, `repetitive_heuristic(dm, nearest_neighbor; do2opt = true)` will perform 2-opt for
each of the `n` nearest neighbor paths.

!!! note
    The repetitive heuristic calls are parallelized with threads. For optimum speed make sure
    Julia is running with multiple threads.
"""
function repetitive_heuristic(dm::Matrix{T},
                              heuristic::Function,
                              repetitive_kw = :firstcity;
							  kwargs...) where {T<:Real}
	# call the heuristic with varying starting cities
	n = size(dm, 1)
	results_list = Vector{Tuple{Vector{Int}, T}}(undef, n)
	Threads.@threads for i in 1:n
		results_list[i] = heuristic(dm; kwargs..., repetitive_kw => i)
	end
	
	bestind, bestcost = 1, results_list[1][2]
	for i in 2:n
		if results_list[i][2] < bestcost
			bestind, bestcost = i, results_list[i][2]
		end
	end
	return results_list[bestind]
end

# helper for readable one-line path costs
# optionally specify the bounds for the subpath we want the cost of
# defaults to the whole path
# but when calculating reversed path costs can help to have subpath costs
function pathcost(distmat::Matrix{T}, path::AbstractArray{S},
                  lb::Int = 1, ub::Int = length(path)) where {T<:Real, S<:Integer}
	cost = zero(T)
	for i in lb:(ub - 1)
		@inbounds cost += distmat[path[i], path[i+1]]
	end
	return cost
end
# calculate the cost of reversing part of a path
# cost of walking along the entire path specified but reversing the sequence from revLow to revHigh, inclusive
function pathcost_rev(distmat::Matrix{T}, path::AbstractArray{S},
                      revLow::Int, revHigh::Int) where {T<:Real, S<:Integer}
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
function inscost(k::Int, after::Int, path::AbstractArray{S}, distmat::Matrix{T}) where {T<:Real, S<:Integer}
	return distmat[path[after], k] + 
		  distmat[k, path[after + 1]] -
		  distmat[path[after], path[after + 1]]
end
