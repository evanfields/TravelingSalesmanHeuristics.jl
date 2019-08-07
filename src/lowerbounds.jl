# I implement several simple but super loose bounds
# These only apply to closed tours

# the cost of a tour must be >= the sum over all vertices of
# the cost of the cheapest edge leaving that vertex
# likewise for the cheapest edge entering that vertex
# since we must go to and leave each vertex
function vertwise_bound(distmat::AbstractMatrix{T}) where {T<:Real}
    # the simple code below would tend to pick out the 0 costs on the diagonal
    # so make a doctored copy of the distance matrix with high costs on the diagonal
    m = maximum(distmat)
    distmat_nodiag = distmat + m * I
    leaving = sum(minimum(distmat_nodiag, dims = 2))
    entering = sum(minimum(distmat_nodiag, dims = 1))
    return maximum([leaving, entering])
end

# helper to get min spanning trees
# returns a (n-1) long Vector of Tuple{Int, Int} where each tuple is an edge in the MST
# and the total weight of the tree
# the matrix passed in must be symmetric or you won't get out the minimum spanning tree
function minspantree(dm::AbstractMatrix{T}) where {T<:Real} # accepts views
    mst_edges = Vector{Tuple{Int, Int}}()
    mst_cost = zero(T)
    n = size(dm, 1)

    # we keep a running list of the distance from each vertex to the partly formed tree
    # rather than using 0 for vertices already in the tree, we use a large value so that we
    # can find the closest non-tree vertex via call to Julia's `findmin`.
    bigval = maximum(dm) + one(T)
    tree_dists = dm[1,:] # distance to tree
    closest_tree_verts = ones(Int, n)
    tree_dists[1] = bigval # vert 1 is in tree now

    for _ in 1:(n-1) # need to add n - 1 other verts to tree
        cost, newvert = findmin(tree_dists)
        treevert = closest_tree_verts[newvert]
        # add costs and edges
        mst_cost += cost
        if treevert < newvert
            push!(mst_edges, (treevert, newvert))
        else
            push!(mst_edges, (newvert, treevert))
        end
        # update distances to tree
        tree_dists[newvert] = bigval
        for i in 1:n
            c = tree_dists[i]
            if c >= bigval # already in tree
                continue
            end
            # maybe this vertex is closer to the new vertex than the prior iteration's tree
            if c > dm[i, newvert]
                tree_dists[i] = dm[i, newvert]
                closest_tree_verts[i] = newvert
            end
        end
    end

    return mst_edges, mst_cost
end

# a simplified/looser version of Held-Karp bounds
# any tour is a spanning tree on (n-1) verts plus two edges
# from the left out vert
# so the maximum over all verts (as the left out vert) of
# MST cost on remaining vertices plus 2 cheapest edges from
# the left out vert is a lower bound
# for extra simplicity, the distance matrix is modified to be symmetric so we can treat
# the underlying graph as undirected. This also doesn't help the bound!
function hkinspired_bound(distmat::AbstractMatrix{T}) where {T<:Real}
    n = size(distmat, 1)
    if size(distmat, 2) != n
        error("Must pass square distance matrix to hkinspired_bound")
    end

    # make a symmetric copy of the distance matrix
    distmat = copy(distmat)
    for i in 1:n, j in 1:n
        if i == j
            continue
        end
        d = min(distmat[i,j], distmat[j,i])
        distmat[i,j] = d
        distmat[j,i] = d
    end

    # get a view of the distmat with one vertex deleted
    function del_vert(v)
        keep = [1:(v-1) ; (v+1):n]
        return view(distmat, keep, keep)
    end

    # make sure min(distmat[v,:]) doesn't pick diagonal elements
    m = maximum(distmat)
    distmat_nodiag = distmat + m * I

    # lower bound the optimal cost by leaving a single vertex out
    # forming spanning tree on the rest
    # connecting the left-out vertex
    function cost_leave_out(v)
        dmprime = del_vert(v)
        _, c = minspantree(dmprime)
        c += minimum(distmat_nodiag[v,:])
        c += minimum(distmat_nodiag[:,v])
        return c
    end

    return maximum(map(cost_leave_out, 1:n))
end

# best lower bound we have
"""
    lowerbound(distmat)

Lower bound the cost of the optimal TSP tour. At present, the bounds considered
are a simple bound based on the minimum cost of entering and exiting each city and
a slightly better bound inspired by the Held-Karp bounds; note that the implementation
here is simpler and less tight than proper HK bounds.

The Held-Karp-inspired bound requires computing many spanning trees. For a faster but
typically looser bound, use `TravelingSalesmanHeuristics.vertwise_bound(distmat)`.

!!! note
    The spanning tree bounds are only correct on symmetric problem instances and will not be
    used if the passed `distmat` is not symmetric. If you wish to use these bounds anyway,
    (e.g. for near-symmetric instances), use `TravelingSalesmanHeuristics.hkinspired_bound`.
"""
function lowerbound(distmat::AbstractMatrix{T} where {T<:Real})
    vb = vertwise_bound(distmat)
    if !issymmetric(distmat)
        return vb
    end
    return max(vb, hkinspired_bound(distmat))
end
