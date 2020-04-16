__precompile__()

module ACTRModels
    using Reexport
    @reexport using Distributions, Parameters, Distributed, Random, StatsFuns, StatsBase
    import Distributions: pdf, logpdf
    import Base: rand
    export ACTR, Declarative, Imaginal, Chunk, defaultFun, LNR, reduceData
    export getChunk, updateLags!, updateRecent!, updateChunk!, modify!, addChunk!
    export retrievalProb, retrievalProbs, retrieve, computeActivation!, get_parm
    export spreadingActivation!, Match, computeRT, retrievalRequest, getSubSet
    export firstChunk, posteriorPredictive, LogNormal′, findIndex, findIndices

    include("Structs.jl")
    include("MemoryFunctions.jl")
    include("LogNormalRace/LogNormalRace.jl")
    include("Utilities/Turing Utilities.jl")
    include("Utilities/install.jl")
end
