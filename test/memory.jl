
function initializeACTR(; parms...)
    chunks = Chunk[
        Chunk(; isa = :bafoon, animal = :dog, name = :Sigma),
        Chunk(; isa = :mammal, animal = :cat, name = :Butters),
        Chunk(; isa = :mammal, animal = :rat, name = :Joy),
        Chunk(; isa = :mammal, animal = :rat, name = :Bernice)
    ]
    memory = Declarative(; memory = chunks)
    imaginal = Imaginal(buffer = typeof(chunks)(undef, 1))
    actr = ACTR(; declarative = memory, imaginal = imaginal, parms...)
    return actr, memory, chunks
end
