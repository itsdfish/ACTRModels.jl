push!(LOAD_PATH,"../src/")

using Documenter
using ACTRModels

makedocs(
    sitename = "ACTRModels",
    format = Documenter.HTML(),
    modules = [ACTRModels],
    pages = ["home" => "index.md",
            "api" => "api.md"]
)

deploydocs(
    repo = "github.com/itsdfish/ACTRModels.jl.git",
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
