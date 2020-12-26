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
- `Imaginal`
- `Chunk`
## Functions 
- `get_chunks`
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
- `print_chunk`
- `print_memory`
"""
module ACTRModels
    using Reexport
    @reexport using Distributions, Parameters, Random
    import Distributions: pdf, logpdf
    import SequentialSamplingModels: LNR
    import Base: rand, match
    export ACTR, Declarative, Imaginal, Chunk, defaultFun, LNR, reduce_data
    export get_chunks, update_lags!, update_recent!, update_chunk!, modify!, add_chunk!
    export retrieval_prob, retrieval_probs, retrieve, compute_activation!, get_parm
    export spreading_activation!, match, compute_RT, retrieval_request, get_subset
    export first_chunk, posterior_predictive, find_index, find_indices
    export import_printing, print_chunk, print_memory

    include("Structs.jl")
    include("MemoryFunctions.jl")
    include("Utilities/Utilities.jl")
end
