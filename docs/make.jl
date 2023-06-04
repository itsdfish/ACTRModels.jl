using Documenter
using ACTRModels

makedocs(
    sitename = "ACTRModels",
    format = Documenter.HTML(),
    modules = [ACTRModels],
    pages = ["home" => "index.md",
            "examples" => ["example 1" => "example1.md",
                            "example 2" => "example2.md"],
            "api" => "api.md"]
)

deploydocs(
    repo = "github.com/itsdfish/ACTRModels.jl.git",
)