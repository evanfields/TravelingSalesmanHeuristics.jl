###
# path improvement heuristics
###

## two-opt

"""
    two_opt(distmat, path)

Improve `path` by doing 2-opt switches (i.e. reversing part of the path) until doing so no
longer reduces the cost. Return a tuple `(improved_path, improved_cost)`.

On large problem instances this heuristic can be slow, but it is highly recommended on small and
medium problem instances.

See also [`simulated_annealing`](@ref) for another path refinement heuristic.
"""
function two_opt(distmat::AbstractMatrix{T}, path::AbstractVector{S}) where {T<:Real, S<:Integer}
    # We can accelerate if the instance is symmetric
    issymmetric(distmat) && (distmat = Symmetric(distmat))
    return _two_opt_logic(distmat, path)
end

function _two_opt_logic(distmat::AbstractMatrix{T}, path::AbstractVector{S}) where {T<:Real, S<:Integer}
    # size checks
    n = length(path)
    if size(distmat, 1) != size(distmat, 2)
        error("Distance matrix passed to two_opt must be square.")
    end

    # don't modify input
    path = deepcopy(path)
    
    # how much must each swap improve the cost?
    thresh = improvement_threshold(T)

    # main loop
    # check every possible switch until no 2-swaps reduce objective
    # if the path passed in is a loop (first/last nodes are the same)
    # then we must keep these the endpoints of the path the same
    # ie just keep it a loop, and therefore it doesn't matter which node is at the end
    # if the path is not a cycle, we should respect the endpoints
    switchLow = 2
    switchHigh = n - 1
    need_to_loop = true # always look for swaps at least once
    while need_to_loop
        need_to_loop = false
        # we can't change the first
        for i in switchLow:(switchHigh-1)
            for j in switchHigh:-1:(i+1)
                cost_change = pathcost_rev_delta(distmat, path, i, j)
                if cost_change + thresh <= 0
                    need_to_loop = true
                    reverse!(path, i, j)
                end
            end
        end
    end
    return path, pathcost(distmat, path)
end

## local brute force


function _list_permutations(x)
    length(x) == 1 && return [[x[1]]]
    length(x) == 2 && return [[x[1], x[2]], [x[2], x[1]]]
    permutations = Vector{Vector{eltype(x)}}()
    for ind in eachindex(x)
        this_el = x[ind]
        others = [x[i] for i in eachindex(x) if i != ind]
        other_permutes = _list_permutations(others)
        for other_permute in other_permutes
            push!(permutations, pushfirst!(other_permute, this_el))
        end
    end
    return permutations
end
_PERMUTATIONS = Dict(i => _list_permutations(1:i) for i in 2:7)

function _local_brute_single_pass(distmat, path, k)
    path = deepcopy(path)
    permutations = _PERMUTATIONS[k]
    # how much must each swap improve the cost?
    max_root_ind = length(path) - k - 1
    for root_ind in 1:max_root_ind
        costs = map(permutations) do permutation
            local_path = vcat(
                path[root_ind],
                [path[root_ind + 1 : root_ind + k][i] for i in permutation],
                path[root_ind + k + 1],
            )
            return pathcost(distmat, local_path)
        end
        best_perm_ind = argmin(costs)
        path[root_ind + 1 : root_ind + k] .= [path[root_ind + 1 : root_ind + k][i] for i in permutations[best_perm_ind]]
    end
    return path
end

function local_brute(distmat, path, k, max_passes = ceil(Int, sqrt(length(path))))
    # size checks
    n = length(path)
    if size(distmat, 1) != size(distmat, 2)
        error("Distance matrix passed to local_brute must be square.")
    end

    # don't modify input
    path = deepcopy(path)
    
    # how much must each swap improve the cost?
    thresh = improvement_threshold(eltype(distmat))

    cur_cost = pathcost(distmat, path)
    passes = 0
    another_pass = true
    while another_pass
        passes += 1
        another_pass = false # default we won't do any more passes, unless we improve
        new_path = _local_brute_single_pass(distmat, path, k)
        new_cost = pathcost(distmat, new_path)
        if new_cost < cur_cost - thresh
            path = new_path
            cur_cost = new_cost
            another_pass = true
        end
        another_pass = another_pass && (passes < max_passes)
    end
    return path, cur_cost
end
