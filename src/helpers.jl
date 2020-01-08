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
function repetitive_heuristic(dm::AbstractMatrix{T},
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
function pathcost(distmat::AbstractMatrix{T}, path::AbstractArray{S},
                  lb::Int = 1, ub::Int = length(path)) where {T<:Real, S<:Integer}
    cost = zero(T)
    for i in lb:(ub - 1)
        @inbounds cost += distmat[path[i], path[i+1]]
    end
    return cost
end

"Compute the cost of walking along the entire path specified but reversing the
sequence from `revLow` to `revHigh`, inclusive."
function pathcost_rev(distmat::AbstractMatrix{T}, path::AbstractArray{S},
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

"Compute the change in cost from reversing the subset of the path from indices
`revLow` to `revHigh`, inclusive."
function pathcost_rev_delta(distmat::AbstractMatrix{T}, path::AbstractArray{S},
                      revLow::Int, revHigh::Int) where {T<:Real, S<:Integer}
    cost_delta = zero(T)
    # if there's an initial unreversed section
    if revLow > 1
        # new step onto the reversed section
        @inbounds cost_delta += distmat[path[revLow - 1], path[revHigh]]
        # no longer pay the cost of old step onto the reversed section
        @inbounds cost_delta -= distmat[path[revLow - 1], path[revLow]]
    end
    # new cost of the reversed section
    for i in revHigh:-1:(revLow + 1)
        @inbounds cost_delta += distmat[path[i], path[i-1]]
    end
    # no longer pay the forward cost of the reversed section
    for i in revLow:(revHigh - 1)
        @inbounds cost_delta -= distmat[path[i], path[i+1]]
       end
    # if there's an unreversed section after the reversed bit
    if revHigh < length(path)
        # new step out of the reversed section
        @inbounds cost_delta += distmat[path[revLow], path[revHigh + 1]]
        # no longer pay the old cost of stepping out of the reversed section
        @inbounds cost_delta -= distmat[path[revHigh], path[revHigh + 1]]
    end
    return cost_delta
end
"Specialized for symmetric matrices: compute the change in cost from
reversing the subset of the path from indices `revLow` to `revHigh`,
inclusive."
function pathcost_rev_delta(distmat::Symmetric, path::AbstractArray{S},
                      revLow::Int, revHigh::Int) where {S<:Integer}
    cost_delta = zero(eltype(distmat))
    # if there's an initial unreversed section
    if revLow > 1
        # new step onto the reversed section
        @inbounds cost_delta += distmat[path[revLow - 1], path[revHigh]]
        # no longer pay the cost of old step onto the reversed section
        @inbounds cost_delta -= distmat[path[revLow - 1], path[revLow]]
    end
    # The actual cost of walking along the reversed section doesn't change
    # because the distance matrix is symmetric.
    # if there's an unreversed section after the reversed bit
    if revHigh < length(path)
        # new step out of the reversed section
        @inbounds cost_delta += distmat[path[revLow], path[revHigh + 1]]
        # no longer pay the old cost of stepping out of the reversed section
        @inbounds cost_delta -= distmat[path[revHigh], path[revHigh + 1]]
    end
    return cost_delta
end

"Due to floating point imprecision, various path refinement heuristics may get
stuck in infinite loops as both doing and un-doing a particular change apparently
improves the path cost. For example, floating point error may suggest that reversing
and un-reversing a path for a symmetric TSP instance improves the cost slightly. To
avoid such false-improvement infinite loops, limit refinement heuristics to
improvements with some minimum magnitude defined by the element type of the distance
matrix."
improvement_threshold(T::Type{<:Integer}) = one(T)
improvement_threshold(T::Type{<:AbstractFloat}) = sqrt(eps(one(T)))
improvement_threshold(T::Type{<:Real}) = sqrt(eps(1.0))

#Cost of inserting city `k` after index `after` in path `path` with costs `distmat`.
function inscost(k::Int, after::Int, path::AbstractArray{S}, distmat::Matrix{T}) where {T<:Real, S<:Integer}
    return distmat[path[after], k] +
           distmat[k, path[after + 1]] -
           distmat[path[after], path[after + 1]]
end
