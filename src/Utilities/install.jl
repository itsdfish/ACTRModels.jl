module install
    using Pkg

    function addPackages(pkg)
        ipks = Pkg.installed()
        !haskey(ipks,pkg) && Pkg.add(pkg)
        return nothing
    end

    packages = ["Revise","MCMCChains","Turing","StatsBase","StatsPlots","Dierckx",
        "QuadGK","DataFrames","Plots","StatsFuns","Parameters","Distributions","Atom","Juno",
        "IJulia","PyPlot","Combinatorics","DynamicHMC","LogDensityProblems"]

    addPackages() = addPackages.(packages)
end
