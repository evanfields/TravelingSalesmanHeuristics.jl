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
- `init_path::Nullable{vector{Int}} = Nullable{Vector{Int}}()`: path to start the annealing from.
    A Nullable{Vector{Int}}. An empty Nullable corresponds to picking a random path; if the 
    Nullable contains a value then this path will be used. Defaults to a random path.
"""
function simulated_annealing{T <: Real}(distmat::Matrix{T}; steps = 50*length(distmat),
										num_starts = 1,
										init_temp = exp(8), final_temp = exp(-6.5),
										init_path::Nullable{Vector{Int}} = Nullable{Vector{Int}}())

	# check inputs
	check_square(distmat, "Must pass a square distance matrix to simulated_annealing.")
	
	# cooling rate: we multiply by a constant mult each step
	cool_rate = (final_temp / init_temp)^(1 / (steps - 1))

	# do SA with a single starting location
	function sahelper()
		temp = init_temp / cool_rate # divide by cool_rate so when we first multiply we get init_temp
		n = size(distmat, 1)
		path = isnull(init_path) ? randpath(n) : copy(get(init_path))
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

	path, cost = sahelper()
	for _ in 2:num_starts
		otherpath, othercost = sahelper()
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
