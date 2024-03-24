__precompile__()
module ACTRModels
using Distributions
using ConcreteStructs
using PrettyTables
using Random

import Base: rand
import Base: match

export AbstractACTR
export ACTR
export Declarative
export Imaginal
export Chunk
export BufferState
export Mod
export Goal
export Visual
export Motor
export VisualLocation
export Procedural
export Rule
export AbstractVisualObject
export VisualObject
export Parms
export AbstractParms
export reduce_data
export get_buffer
export set_buffer!
export get_chunks
export update_lags!
export update_recent!
export update_chunk!
export modify!
export add_chunk!
export retrieval_prob
export retrieval_probs
export retrieve
export compute_activation!
export get_parm
export match
export compute_RT
export retrieval_request
export first_chunk
export posterior_predictive
export find_index
export find_indices
export get_mean_activations
export get_visicon
export get_iconic_memory
export get_rules
export get_time
export set_time!
export add_time!
export reset_time!
export rnd_time
export get_name
export blend_chunks
export blended_activation

include("Structs.jl")
include("Utilities/Utilities.jl")
include("MemoryFunctions.jl")
end
