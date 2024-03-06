module TravelingSalesmanHeuristics

using Random, LinearAlgebra

include("helpers.jl")
include("generation_heuristics.jl")
include("simulated_annealing.jl")
include("lowerbounds.jl")
include("refinements.jl")

export solve_tsp, lowerbound, repetitive_heuristic, two_opt,
       nearest_neighbor, cheapest_insertion, simulated_annealing, farthest_insertion
"""
    solve_tsp(distmat; quality_factor = 40)

Approximately solve a TSP by specifying a distance matrix. Return a tuple `(path, cost)`.

The optional keyword `quality_factor` (real number in [0,100]; defaults to 40) specifies the
tradeoff between computation time and quality of solution returned. Higher values
tend to lead to better solutions found at the cost of more computation time.

!!! note
    It is not guaranteed that a call with a high `quality_factor` will always run slower or
    return a better solution than a call with a lower `quality_factor`, though this is
    typically the case. A `quality_factor` of 100 neither guarantees an optimal solution
    nor the best solution  that can be found via extensive use of the methods in this package.

!!! danger
    TravelingSalesmanHeuristics does not support distance matrices with arbitrary indexing; indices must be `1:n` in both dimensions for `n` cities.

See also: individual heuristic methods such as [`farthest_insertion`](@ref)
"""
function solve_tsp(distmat::AbstractMatrix{T}; quality_factor::Real = 40.0) where {T<:Real}
    if quality_factor < 0 || quality_factor > 100
        @warn "quality_factor keyword passed to solve_tsp must be in [0,100]"
        quality_factor = clamp(quality_factor, 0, 100)
    end

    lowest_threshold = 5

    # begin adding heuristics as dictated by the quality_factor,
    # starting with the very fastest
    answers = Vector{Tuple{Vector{Int}, T}}()
    push!(answers, farthest_insertion(distmat; do2opt = false))
    if quality_factor < lowest_threshold # fastest heuristic and out
        return answers[1]
    end
    # otherwise, we'll try several heuristics and return the best


    # add any nearest neighbor heuristics as dictated by quality_factor
    if quality_factor >= 60 # repetitive-NN, 2-opt on each iter
        push!(answers, repetitive_heuristic(distmat, nearest_neighbor; do2opt = true))
    elseif quality_factor >= 25 # repetitive-NN, 2-opt on final
        rnnpath, _ = repetitive_heuristic(distmat, nearest_neighbor; do2opt = false)
        push!(answers, two_opt(distmat, rnnpath))
    elseif quality_factor >= 15 # NN w/ 2-opt
        push!(answers, nearest_neighbor(distmat; do2opt = true))
    end

    # farthest insertions as needed
    if quality_factor >= 70 # repetitive-FI, 2-opt on each
        push!(answers, repetitive_heuristic(distmat, farthest_insertion; do2opt = true))
    elseif quality_factor >= 5 # FI w/ 2-opt
        push!(answers, farthest_insertion(distmat; do2opt = true))
    end

    # cheapest insertions
    if quality_factor >= 90 # repetitive-CI w/ 2-opt on each
        push!(answers, repetitive_heuristic(distmat, cheapest_insertion; do2opt = true))
    elseif quality_factor >= 35
        push!(answers, cheapest_insertion(distmat; do2opt = true))
    end

    # simulated annealing refinement, seeded with best so far
    if quality_factor >= 80
        _, bestind = findmin([pc[2] for pc in answers])
        bestpath, bestcost = answers[bestind]
        nstart = ceil(Int, (quality_factor - 79)/5)
        push!(answers,
              simulated_annealing(distmat; num_starts = nstart, init_path = bestpath)
        )
    end

    # pick best
    _, bestind = findmin([pc[2] for pc in answers])
    return answers[bestind]
end

end # module
