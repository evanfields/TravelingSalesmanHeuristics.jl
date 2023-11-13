#=
This file contains a set of synthetic TSP test cases, plus some small helper functions
for running the test cases. It's mostly intended for comparing algorithms in development
and probably isn't of much use to end users. Note the dependence on DataFrames and
Distributions as well, which aren't part of the TravelingSalesmanHeuristics environment.
=#

using Random
using LinearAlgebra: norm

using DataFrames
using Distributions
using TravelingSalesmanHeuristics
TSP = TravelingSalesmanHeuristics

struct TestCase
    distmat
    description::String
end

"""
    runcase(alg, case)

Test an algorithm on a TestCase. `alg` must be a function `distmat -> (path, cost)`.
Return a NamedTuple describing the result. The `bound` and `excess` keys in the
resulting tuple are respectively the vertwise bound and a simple scale-adjusted
cost (lower is still better)."""
function runcase(alg, case::TestCase)
    time = @elapsed path, cost = alg(case.distmat)
    path = TSP.rotate_circuit(path, 1)
    bound = TSP.vertwise_bound(case.distmat)
    excess = (cost - bound) / abs(bound)
    return (;time, path, cost, bound, excess, description = case.description)
end

"""Run multiple test cases and return the result as a DataFrame.
`alg` should be a function `distmat -> (path, cost)`."""
function runcases(alg, cases)
    return DataFrame(runcase.(alg, cases))
end


"Euclidean distance matrix from a matrix of points, one col per point, one row per dim"
function _distmat_from_pts(pts)
    n = size(pts, 2)
    return [norm(pts[:,i] - pts[:,j]) for i in 1:n, j in 1:n]
end

function generate_cases_euclidean(;
    seed = 47,
    dimensions = [2, 5, 15],
    ns = [5, 25, 100, 500],
)
    Random.seed!(seed)
    cases = TestCase[]
    for d in dimensions, n in ns
        # hypercube
        pts = rand(d, n)
        dm = _distmat_from_pts(pts)
        push!(cases, TestCase(dm, "euclidean_hypercube_$(d)d_$(n)n"))
        # squashed hypercube
        pts = rand(d, n)
        pts[1:(d ÷ 2), :] ./= 10
        dm = _distmat_from_pts(pts)
        push!(cases, TestCase(dm, "euclidean_squashedhypercube_$(d)d_$(n)n"))
        # hypersphere shell
        pts = randn(d, n)
        for i in 1:n
            pts[:,i] ./= norm(pts[:,i])
        end
        dm = _distmat_from_pts(pts)
        push!(cases, TestCase(dm, "euclidean_sphereshell_$(d)d_$(n)n"))
    end
    return cases
end

function generate_cases_euclidean_plus_noise(;
    dists = [
        Normal(),
        Exponential(1),
    ],
    euclidean_args...
)
    euclidean_cases = generate_cases_euclidean(euclidean_args...)
    return [
        TestCase(
            case.distmat .+ rand(dist, size(case.distmat)),
            case.description * "_plus_" * string(dist)
        )
        for case in euclidean_cases
        for dist in dists
    ]
end