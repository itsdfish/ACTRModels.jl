using Documenter
using ACTRModels

makedocs(
    warnonly = true,
    sitename = "ACTRModels",
    format = Documenter.HTML(
        assets = [
            asset(
                "https://fonts.googleapis.com/css?family=Montserrat|Source+Code+Pro&display=swap",
                class = :css
            )
        ],
        collapselevel = 1
    ),
    modules = [ACTRModels],
    pages = [
        "home" => "index.md",
        "examples" => [
            "example 1" => "example1.md",
            "example 2" => "example2.md",
            "example 3" => "example3.md"
        ],
        "api" => "api.md"
    ]
)

deploydocs(repo = "github.com/itsdfish/ACTRModels.jl.git")
