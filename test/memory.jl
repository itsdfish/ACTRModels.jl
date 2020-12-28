#Allows chunk to have hetergenious type
mutable struct Imaginal1
    buffer::Array{Chunk,1}
    state::BufferState
    ω::Float64
    denoms::Vector{Int64}
end

function Imaginal1(;chunk=Chunk(), ω=1.0, denoms=Int64[]) 
    state = BufferState()
    Imaginal1([chunk], state, ω, denoms)
end


function initializeACTR(;parms...)
    chunks = Chunk[Chunk(;isa=:bafoon,animal=:dog,name=:Sigma),
        Chunk(;isa=:mammal,animal=:cat,name=:Butters),
        Chunk(;isa=:mammal,animal=:rat,name=:Joy),
        Chunk(;isa=:mammal,animal=:rat,name=:Bernice)]
    memory = Declarative(;memory=chunks)
    actr = ACTR(;declarative=memory, imaginal=Imaginal1(), parms...)
    return actr,memory,chunks
end
