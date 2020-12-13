__precompile__()

module ACTRModels
    using Reexport
    @reexport using Distributions, Parameters, Random, StatsFuns, StatsBase
    import Distributions: pdf, logpdf
    import SequentialSamplingModels: LNR
    import Base: rand, match
    export ACTR, Declarative, Imaginal, Chunk, defaultFun, LNR, reduce_data
    export get_chunk, update_lags!, update_recent!, update_chunk!, modify!, add_chunk!
    export retrieval_prob, retrieval_probs, retrieve, compute_activation!, get_parm
    export spreading_activation!, match, compute_RT, retrieval_request, get_subset
    export first_chunk, posterior_predictive, find_index, find_indices
    export LNR

    include("Structs.jl")
    include("MemoryFunctions.jl")
    include("Utilities/Turing_Utilities.jl")
end
