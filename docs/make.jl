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

