# this file contains code for the simulated annealing TSP heuristic

"""
.. simulated_annealing(distmat; ...) ..

Use a simulated annealing strategy to return a closed tour.

Optional arguments:

- steps: number of steps to take; defaults to 10n^2 where n is number of cities

- num_starts: number of times to run the simulated annealing algorithm, each time
	starting with a random path. Defaults to 1.

- cooling_schedule: a function mapping the index of a step to a temperature. Probably
	this function should approach 1 as input gets large; this corresponds to always
	accepting moves which improve the objective function.
"""
function simulated_annealing{T <: Real}(distmat::Matrix{T}; steps = 10*length(distmat),
										num_starts = 1,
										init_temp = 5000, final_temp = 1e-5)

	# cooling rate: we multiply by a constant mult each step
	cool_rate = (final_temp / init_temp)^(1 / (steps - 1))

	# do SA with a single starting location
	function sahelper()
		temp = init_temp / cool_rate # divide by cool_rate so when we first multiply we get init_temp
		n = size(distmat, 1)
		path = randpath(n)
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
