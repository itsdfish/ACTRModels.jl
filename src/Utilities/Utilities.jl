import Distributions: rand, logpdf, pdf, estimate

function sample_chain(chain)
    parms = (Symbol.(chain.name_map.parameters)...,)
    n = size(chain, 1)*size(chain, 3)
    idx = rand(1:n)
    vals = map(x -> chain[x][idx], parms)
    return NamedTuple{parms}(vals)
end

function posterior_predictive(m, chain, f=x -> x)
    parms = sample_chain(chain)
    return f(m(parms))
end

function posterior_predictive(model, chain, n_samples::Int, f=x -> x)
    return map(x -> posterior_predictive(model, chain, f), 1:n_samples)
end

find_index(actr::ACTR; criteria...) = find_index(actr.declarative.memory;criteria...)

function find_index(chunks::Array{<:Chunk,1}; criteria...)
    for (i,c) in enumerate(chunks)
        match(c;criteria...) ? (return i) : nothing
    end
    return -100
end

find_index(actr::ACTR, funs...; criteria...) = find_index(actr.declarative.memory, funs...; criteria...)

function find_index(chunks::Array{<:Chunk,1}, funs...; criteria...)
    for (i,c) in enumerate(chunks)
        match(c, funs...; criteria...) ? (return i) : nothing
    end
    return -100
end

find_indices(actr::ACTR; criteria...) = find_indices(actr.declarative.memory; criteria...)

function find_indices(chunks::Array{<:Chunk,1}; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

find_indices(actr::ACTR, funs...; criteria...) = find_indices(actr.declarative.memory, funs...; criteria...)

function find_indices(chunks::Array{<:Chunk,1}, funs...; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c, funs...; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

"""
**print_memory** prints all chunks in declarative memory and returns a DataFrame.
- `actr`: an ACTR object
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function signature
````julia
print_memory(actr::AbstractACTR; fields=(:slots,:act_blc,:act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_memory(actr::AbstractACTR; fields=(:slots,:act_blc,:act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    return print_memory(actr.declarative; fields=fields)
end

"""
**print_memory** prints all chunks in declarative memory and returns a DataFrame.
- `memory`: a declarative memory object
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function signature
````julia
print_memory(memory::Declarative; fields=(:slots,:act_blc,:act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_memory(memory::Declarative; fields=(:slots,:act_blc,:act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    return print_memory(memory.memory; fields=fields)
end

"""
**print_memory** prints all chunks in declarative memory and returns a DataFrame.
- `chunks`: a vector of chunks
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function signature
````julia
print_memory(chunks; fields=(:slots,:act_blc,:act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_memory(chunks; fields=(:slots,:act_blc,:act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    df = DataFrame(chunks)
    slots = map(x->x.slots, chunks)
    df_slots = DataFrame()
    for chunk in chunks
        push!(df_slots, chunk.slots; cols=:union)
    end
    fields == :all ? nothing : select!(df, fields...)
    df = [df_slots df]
    select!(df, Not(:slots))
    return df
end

"""
**print_chunk** prints the contents of a chunk and returns a DataFrame.
- `chunk`: a chunk
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function signature
````julia
print_chunk(chunk; fields=(:slots,:act_blc, :act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_chunk(chunk; fields=(:slots,:act_blc, :act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    return print_memory([chunk]; fields=fields)
end
