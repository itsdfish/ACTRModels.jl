#Allows chunk to have hetergenious type
mutable struct Imaginal1{T1}
    chunk::Chunk
    ω::T1
    denoms::Vector{Int64}
end

Imaginal1(;chunk=Chunk(),ω=1.0,denoms=Int64[])=Imaginal1(chunk,ω,denoms)
function initializeACTR(;parms...)
    chunks = Chunk[Chunk(;isa=:bafoon,animal=:dog,name=:Sigma),
        Chunk(;isa=:mammal,animal=:cat,name=:Butters),
        Chunk(;isa=:mammal,animal=:rat,name=:Joy),
        Chunk(;isa=:mammal,animal=:rat,name=:Bernice)]
    memory = Declarative(;memory=chunks,parms...)
    actr = ACTR(;declarative=memory,imaginal=Imaginal1())
    return actr,memory,chunks
end
