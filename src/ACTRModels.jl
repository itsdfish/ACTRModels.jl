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
    using DiscreteEventsLite, ConcreteStructs, DataStructures
    import Distributions: pdf, logpdf
    import SequentialSamplingModels: LNR
    import DiscreteEventsLite: run!, last_event!, is_running, print_event
    import Base: rand, match
    export ACTR, Declarative, Imaginal, Chunk, BufferState, Mod, AbstractTask 
    export Goal, Visual, Motor, VisualLocation, Procedural, Rule
    export AbstractVisualObject, VisualObject
    export defaultFun, LNR, reduce_data, get_buffer, set_buffer! 
    export get_chunks, update_lags!, update_recent!, update_chunk!, modify!, add_chunk!
    export retrieval_prob, retrieval_probs, retrieve, compute_activation!, get_parm
    export spreading_activation!, match, compute_RT, retrieval_request, get_subset
    export first_chunk, posterior_predictive, find_index, find_indices, get_mean_activations
    export import_printing, print_chunk, print_memory, get_visicon, get_iconic_memory
    export run!, vo_to_chunk, add_to_visicon!, clear_buffer!, add_to_buffer!, get_time, attending!
    export attend!, retrieving!, retrieve!, responding!, respond!, press_key!

    include("Structs.jl")
    include("MemoryFunctions.jl")
    include("Procedural_Memory_Functions.jl")
    include("simulator.jl")
    include("Utilities/Utilities.jl")
end
