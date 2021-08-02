__precompile__()
"""
An outline of the API for ACTRModels is presented below. In the REPL, use `?` to see documentation, 
    i.e., 

````julia 
? print_memory

to see documentation for `print_memory`.
````
# API
## Types
- `ACTR`
- `Declarative`
- `Goal`
- `Imaginal`
- `Chunk`
- `Visual`
- `VisualLocation`
- `Motor`
- `Procedural`
- `Rule`
## Functions 
- `get_chunks`
- `get_iconic_memory`
- `get_visicon`
- `get_buffer`
- `set_buffer!`
- `update_lags!`
- `update_recent!`
- `update_chunk!`
- `modify!`
- `add_chunk!`
- `retrieval_prob`
- `retrieval_probs`
- `retrieve`
- `compute_activation!`
- `get_parm`
- `spreading_activation`
- `match`
- `compute_RT`
- `retrieval_request`
- `get_subset`
- `first_chunk`
- `posterior_predictive`
- `find_index`
- `find_indices`
- `import_printing`
- `print_chunk`
- `print_memory`
-  `run`
- `get_mean_activations`
"""
module ACTRModels
    using Reexport
    @reexport using Distributions, Parameters, Random, StatsBase, StatsFuns
    using  ConcreteStructs, PrettyTables
    import Distributions: pdf, logpdf
    import SequentialSamplingModels: LNR
    import Base: rand, match
    export ACTR, Declarative, Imaginal, Chunk, BufferState, Mod 
    export Goal, Visual, Motor, VisualLocation, Procedural, Rule
    export AbstractVisualObject, VisualObject, Parms, AbstractParms
    export defaultFun, LNR, reduce_data, get_buffer, set_buffer! 
    export get_chunks, update_lags!, update_recent!, update_chunk!, modify!, add_chunk!
    export retrieval_prob, retrieval_probs, retrieve, compute_activation!, get_parm
    export spreading_activation!, match, compute_RT, retrieval_request, get_subset
    export first_chunk, posterior_predictive, find_index, find_indices, get_mean_activations
    export get_visicon, get_iconic_memory
    export get_time, add_time, reset_time!, rnd_time

    include("Structs.jl")
    include("MemoryFunctions.jl")
    include("Utilities/Utilities.jl")
end
