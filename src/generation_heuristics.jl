###
# path generation heuristics
###

"""
    nearest_neighbor(distmat)

Approximately solve a TSP using the nearest neighbor heuristic. `distmat` is a square real matrix
where distmat[i,j] represents the distance from city `i` to city `j`. The matrix needn't be
symmetric and can contain negative values. Return a tuple `(path, pathcost)`.

# Optional keyword arguments:
- `firstcity::Union{Int, Nothing}`: specifies the city to begin the path on. Passing `nothing` or
    not specifying a value corresponds to random selection.
- `closepath::Bool = true`: whether to include the arc from the last city visited back to the
    first city in cost calculations. If true, the first city appears first and last in the path.
- `do2opt::Bool = true`: whether to refine the path found by 2-opt switches (corresponds to
    removing path crossings in the planar Euclidean case).
"""
function nearest_neighbor(distmat::AbstractMatrix{T} where {T<:Real};
                          firstcity::Union{Int, Nothing} = rand(1:size(distmat, 1)),
                          repetitive::Bool = false,
                          closepath::Bool = true,
                          do2opt::Bool = true)
    # must have a square matrix
    num_cities = check_square(distmat, "Must pass a square distance matrix to nearest_neighbor")

    # extract a safe int value for firstcity
    if firstcity == nothing # random first city
        firstcityint = rand(1:num_cities)
    else # an int was passed
        firstcityint = firstcity
        if !(1 <= firstcityint <= num_cities)
            error("firstcity of $(firstcity) passed to `nearest_neighbor`" *
                  " out of range [1, $(num_cities)]")
        end
    end

    # calling with KW repetitive is deprecated; pass the call to repetitive_heuristic
    if repetitive
        @warn ("Calling `nearest_neighbor` with keyword `repetitive` is deprecated;'" *
             " instead call `repetitive_heuristic(distmat, nearest_neighbor; kwargs...)`")
        return repetitive_heuristic(distmat, nearest_neighbor;
                                    closepath = closepath, do2opt = do2opt)
    end

    # put first city on path
    path = Vector{Int}()
    push!(path, firstcityint)

    # cities to visit
    citiesToVisit = collect(1:(firstcityint - 1))
    append!(citiesToVisit, collect((firstcityint + 1):num_cities))

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
    cheapest_insertion(distmat::Matrix, initpath::AbstractArray{Int})


Given a distance matrix and an initial path, complete the tour by repeatedly doing the cheapest
insertion. Return a tuple `(path, cost)`. The initial path must have length at least 2, but can
be simply `[i, i]` for some city index `i` which corresponds to starting with a loop at city `i`.

!!! note
    Insertions are always in the interior of the current path so this heuristic can also be used for
    non-closed TSP paths.

Currently the implementation is a naive ``n^3`` algorithm.
"""
function cheapest_insertion(distmat::AbstractMatrix{T}, initpath::AbstractVector{S}) where {T<:Real, S<:Integer}
    check_square(distmat, "Distance matrix passed to cheapest_insertion must be square.")

    n = size(distmat, 1)
    path = Vector{Int}(initpath)

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
    cheapest_insertion(distmat; ...)


Complete a tour using cheapest insertion with a single-city loop as the initial path. Return a
tuple `(path, cost)`.

### Optional keyword arguments:
- `firstcity::Union{Int, Nothing}`: specifies the city to begin the path on. Passing `nothing` or
    not specifying a value corresponds to random selection.
- `do2opt::Bool = true`: whether to improve the path found by 2-opt swaps.
"""
function cheapest_insertion(distmat::AbstractMatrix{T} where{T<:Real};
                            firstcity::Union{Int, Nothing} = rand(1:size(distmat, 1)),
                            repetitive::Bool = false,
                            do2opt::Bool = true)
    #infer size
    num_cities = size(distmat, 1)

    # calling with KW repetitive is deprecated; pass the call to repetitive_heuristic
    if repetitive
        @warn "Calling `cheapest_insertionr` with keyword `repetitive` is deprecated;'" *
             " instead call `repetitive_heuristic(distmat, cheapest_insertion; kwargs...)`"
        return repetitive_heuristic(distmat, cheapest_insertion; do2opt = do2opt)
    end

    # extract a safe int value for firstcity
    if firstcity == nothing # random first city
        firstcityint = rand(1:num_cities)
    else # an int was passed
        firstcityint = firstcity
        if !(1 <= firstcityint <= num_cities)
            error("firstcity of $(firstcity) passed to `cheapest_insertion`" *
                  " out of range [1, $(num_cities)]")
        end
    end

    # okay, we're not repetitive, put a loop on the first city
    path, cost = cheapest_insertion(distmat, [firstcityint, firstcityint])

    # user may have asked for 2-opt refinement
    if do2opt
        path, cost = two_opt(distmat, path)
    end

    return path, cost
end

"""
    farthest_insertion(distmat; ...)

Generate a TSP path using the farthest insertion strategy. `distmat` must be a square real matrix.
Return a tuple `(path, cost)`.

### Optional arguments:
- `firstCity::Int`: specifies the city to begin the path on. Not specifying a value corresponds
    to random selection.
- `do2opt::Bool = true`: whether to improve the path by 2-opt swaps.
"""
function farthest_insertion(distmat::AbstractMatrix{T};
                            firstcity::Int = rand(1:size(distmat, 1)),
                            do2opt::Bool = true) where {T<:Real}
    n = check_square(distmat, "Must pass square distance matrix to farthest_insertion.")
    if firstcity < 1 || firstcity > n
        error("First city for farthest_insertion must be in [1,...,n]")
    end
    smallval = minimum(distmat) - one(T) # will never be the max

    path = Int[firstcity, firstcity]
    sizehint!(path, n + 1)
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

    if do2opt
        path, _ = two_opt(distmat, path)
    end

    return path, pathcost(distmat, path)
end
