__precompile__()

module ACTRModels
    using Reexport
    @reexport using Distributions, Parameters, Distributed, Random, StatsFuns, StatsBase
    import Distributions: pdf, logpdf
    import Base: rand, match
    export ACTR, Declarative, Imaginal, Chunk, defaultFun, LNR, reduce_data
    export get_chunk, update_lags!, update_recent!, update_chunk!, modify!, add_chunk!
    export retrieval_prob, retrieval_probs, retrieve, compute_activation!, get_parm
    export spreading_activation!, match, compute_RT, retrieval_request, get_subset
    export first_chunk, posterior_predictive, LogNormal′, find_index, find_indices

    include("Structs.jl")
    include("MemoryFunctions.jl")
    include("LogNormalRace/LogNormalRace.jl")
    include("Utilities/Turing Utilities.jl")
end
