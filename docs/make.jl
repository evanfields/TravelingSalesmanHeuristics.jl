using Documenter, TravelingSalesmanHeuristics

makedocs(
	format = :html,
	sitename = "Traveling Salesman Heuristics",
	pages = [
		"Home" => "index.md",
		"Heuristics" => "heuristics.md",
		"Examples" => "examples.md"
	]
)

deploydocs(
    repo   = "github.com/evanfields/TravelingSalesmanHeuristics.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
	julia  = "0.7",
	osname = "linux"
)
