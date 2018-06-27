# this file contains code for the simulated annealing TSP heuristic

"""
  simulated_annealing(distmat; ...)

Use a simulated annealing strategy to return a closed tour. The temperature
decays exponentially from `init_temp` to `final_temp`. Return a tuple `(path, cost)`.

### Optional keyword arguments:
- `steps::Int = 50n^2`: number of steps to take; defaults to 50n^2 where n is number of cities
- `num_starts::Int = 1`: number of times to run the simulated annealing algorithm, each time
    starting with a random path, or `init_path` if non-null. Defaults to 1.
- `init_temp::Real = exp(8)`: initial temperature which controls initial chance of accepting an
    inferior tour.
- `final_temp::Real = exp(-6.5)` final temperature which controls final chance of accepting an
    inferior tour; lower values roughly correspond to a longer period of 2-opt.
- `init_path::Union{Vector{Int}, Nothing} = nothing`: path to start the annealing from.
    Either a `Vector{Int}` or `nothing`. If a `Vector{Int}` is given, it will be used as the initial path;
    otherwise a random initial path is used.
"""
function simulated_annealing(distmat::Matrix{T} where {T<:Real};
                             steps = 50*length(distmat),
							 num_starts = 1,
							 init_temp = exp(8), final_temp = exp(-6.5),
							 init_path::Union{Vector{Int}, Nothing} = nothing)

	# check inputs
	n = check_square(distmat, "Must pass a square distance matrix to simulated_annealing.")
	
	# cooling rate: we multiply by a constant mult each step
	cool_rate = (final_temp / init_temp)^(1 / (steps - 1))

	# do SA with a single starting path
	function sahelper!(path)
		temp = init_temp / cool_rate # divide by cool_rate so when we first multiply we get init_temp
		n = size(distmat, 1)
		cost_cur = pathcost(distmat, path)

		for i in 1:steps
			temp *= cool_rate

			# take a step
			# keep first and last cities fixed
			first, last = rand(2:n), rand(2:n)
			if first > last
				first, last = last, first
			end
			cost_other = pathcost_rev(distmat, path, first, last)
			@fastmath accept = cost_other < cost_cur ? true : rand() < exp((cost_cur - cost_other) / temp)
			# should we accept?
			if accept
				reverse!(path, first, last)
				cost_cur = cost_other
			end
		end

		return path, cost_cur
	end

	# unpack the initial path
	if init_path == nothing
		randstart = true
		path = randpath(n)
	else
		if !legal_circuit(init_path)
			error("The init_path passed to simulated_annealing must be a legal circuit.")
		end
		randstart = false
		path = init_path
	end
	cost = pathcost(distmat, path)
	for _ in 1:num_starts
		path_this_start = randstart ? randpath(n) : deepcopy(init_path)
		otherpath, othercost = sahelper!(path_this_start)
		if othercost < cost
			cost = othercost
			path = otherpath
		end
	end

	return path, cost
end

function randpath(n)
	path = 1:n |> collect |> shuffle
	push!(path, path[1]) # loop
	return path
end
