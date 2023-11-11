push!(LOAD_PATH,"../src/")
using Documenter, TravelingSalesmanHeuristics

makedocs(
	format = Documenter.HTML(),
	sitename = "Traveling Salesman Heuristics",
	pages = [
		"Home" => "index.md",
		"Heuristics" => "heuristics.md",
		"Examples" => "examples.md"
	]
)

deploydocs(
    repo = "github.com/evanfields/TravelingSalesmanHeuristics.jl.git",
)
