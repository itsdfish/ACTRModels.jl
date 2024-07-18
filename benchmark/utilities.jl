function populate_memory(n_chunks)
    return [Chunk(; slot = i, s = rand(1:10)) for i ∈ 1:n_chunks]
end

function create_model(n_chunks; parms...)
    chunks = populate_memory(n_chunks)
    declarative = Declarative(; memory = chunks)
    imaginal = Imaginal(buffer = chunks[1])
    return ACTR(; declarative, imaginal, parms...)
end
