function populateMemory(act = 0.0)
    chunks = [Chunk(object = :shark, attribute = :dangerous, value = :True, act = act)]
    push!(
        chunks,
        Chunk(object = :shark, attribute = :locomotion, value = :swimming, act = act)
    )
    push!(chunks, Chunk(object = :shark, attribute = :category, value = :fish, act = act))
    push!(chunks, Chunk(object = :salmon, attribute = :edible, value = :True, act = act))
    push!(
        chunks,
        Chunk(object = :salmon, attribute = :locomotion, value = :swimming, act = act)
    )
    push!(chunks, Chunk(object = :salmon, attribute = :category, value = :fish, act = act))
    push!(chunks, Chunk(object = :fish, attribute = :breath, value = :gills, act = act))
    push!(
        chunks,
        Chunk(object = :fish, attribute = :locomotion, value = :swimming, act = act)
    )
    push!(chunks, Chunk(object = :fish, attribute = :category, value = :animal, act = act))
    push!(chunks, Chunk(object = :animal, attribute = :moves, value = :True, act = act))
    push!(chunks, Chunk(object = :animal, attribute = :skin, value = :True, act = act))
    push!(chunks, Chunk(object = :canary, attribute = :color, value = :yellow, act = act))
    push!(chunks, Chunk(object = :canary, attribute = :sings, value = :True, act = act))
    push!(chunks, Chunk(object = :canary, attribute = :category, value = :bird, act = act))
    push!(chunks, Chunk(object = :ostritch, attribute = :flies, value = :False, act = act))
    push!(chunks, Chunk(object = :ostritch, attribute = :height, value = :tall, act = act))
    push!(
        chunks,
        Chunk(object = :ostritch, attribute = :category, value = :bird, act = act)
    )
    push!(chunks, Chunk(object = :bird, attribute = :wings, value = :True, act = act))
    push!(
        chunks,
        Chunk(object = :bird, attribute = :locomotion, value = :flying, act = act)
    )
    push!(chunks, Chunk(object = :bird, attribute = :category, value = :animal, act = act))
    return chunks
end
