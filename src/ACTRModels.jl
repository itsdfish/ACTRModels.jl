__precompile__()
module ACTRModels
    using Reexport
    @reexport using Distributions, Parameters, Random, StatsBase, StatsFuns
    using  ConcreteStructs, PrettyTables
    import Distributions: pdf, logpdf
    import SequentialSamplingModels: LNR
    import Base: rand, match
    export AbstractACTR, ACTR, Declarative, Imaginal, Chunk, BufferState, Mod 
    export Goal, Visual, Motor, VisualLocation, Procedural, Rule
    export AbstractVisualObject, VisualObject, Parms, AbstractParms
    export LNR, reduce_data, get_buffer, set_buffer! 
    export get_chunks, update_lags!, update_recent!, update_chunk!, modify!, add_chunk!
    export retrieval_prob, retrieval_probs, retrieve, compute_activation!, get_parm
    export spreading_activation!, match, compute_RT, retrieval_request, get_subset
    export first_chunk, posterior_predictive, find_index, find_indices, get_mean_activations
    export get_visicon, get_iconic_memory, get_rules
    export get_time, set_time!, add_time!, reset_time!, rnd_time, get_name
    export blend_chunks, blended_activation

    include("Structs.jl")
    include("Utilities/Utilities.jl")
    include("MemoryFunctions.jl")
end
