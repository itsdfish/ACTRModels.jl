import Distributions: rand, logpdf, pdf, estimate

function sample_chain(chain)
    parms = (Symbol.(chain.name_map.parameters)...,)
    n = size(chain, 1)*size(chain, 3)
    idx = rand(1:n)
    vals = map(x -> chain[x][idx], parms)
    return NamedTuple{parms}(vals)
end

function _posterior_predictive(m, chain, f=x -> x)
    parms = sample_chain(chain)
    return f(m(parms))
end

"""
**posterior_predictive** returns posterior predictive distribution and optionally applies function to samples 
    on each replication
- `model`: the data generating function of a model 
- `chain`: an MCMCChains chain object
- `n_samples`: the number of samples 
- `f`: a function that is applied to each sample from posterior predictive distribution
Function Signature
````julia
posterior_predictive(model, chain, n_samples::Int, f=x -> x)
````
"""
function posterior_predictive(model, chain, n_samples::Int, f=x -> x)
    return map(x -> _posterior_predictive(model, chain, f), 1:n_samples)
end

find_index(actr::AbstractACTR; criteria...) = find_index(actr.declarative.memory; criteria...)

"""
**find_index** returns the index of first chunk that matches a set of criteria
- `chunks`: an array of chunks
- `criteria`: a set of keyword arguments for slot-value pairs

Function Signature
````julia
find_index(chunks::Array{<:Chunk,1}; criteria...)
````
## Example
````julia
chunks = [Chunk(animal=:dog), Chunk(animal=cat)]
find_index(chunks; animal=:dog)
````
"""
function find_index(chunks::Array{<:Chunk,1}; criteria...)
    for (i,c) in enumerate(chunks)
        match(c;criteria...) ? (return i) : nothing
    end
    return -100
end

"""
**find_index** returns the index of first chunk that matches a set of criteria
- `actr`: ACTR object
- `funs`: a set of functions
- `criteria`: a set of keyword arguments for slot-value pairs

Function Signature
````julia
find_index(actr::ACTR, funs...; criteria...)
````
## Example
````julia
chunks = [Chunk(animal=:dog), Chunk(animal=cat)]
find_index(chunks; animal=:dog)
````
"""
find_index(actr::ACTR, funs...; criteria...) = find_index(actr.declarative.memory, funs...; criteria...)

"""
**find_index** returns the index of first chunk that matches a set of criteria
- `chunks`: an array of chunks
- `funs`: a set of functions
- `criteria`: a set of keyword arguments for slot-value pairs

Function Signature
````julia
find_index(chunks::Array{<:Chunk,1}; criteria...)
````
## Example
````julia
chunks = [Chunk(animal=:dog), Chunk(animal=cat)]
find_index(chunks; animal=:dog)
````
"""
function find_index(chunks::Array{<:Chunk,1}, funs...; criteria...)
    for (i,c) in enumerate(chunks)
        match(c, funs...; criteria...) ? (return i) : nothing
    end
    return -100
end

"""
**find_indices** returns the index of first chunk that matches a set of criteria
- `actr`: an ACTR object
- `criteria`: a set of keyword arguments for slot-value pairs

Function Signature
````julia
find_indices(actr::ACTR; criteria...)
````
## Example
````julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
````
"""
find_indices(actr::ACTR; criteria...) = find_indices(actr.declarative.memory; criteria...)

"""
**find_indices** returns the index of first chunk that matches a set of criteria
- `chunks`: an array of chunks
- `criteria`: a set of keyword arguments for slot-value pairs

Function Signature
````julia
find_indices(actr::ACTR; criteria...)
````
## Example
````julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
````
"""
function find_indices(chunks::Array{<:Chunk,1}; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

"""
**find_indices** returns the index of first chunk that matches a set of criteria
- `actr`: an ACTR object
- `funs`: a set of functions
- `criteria`: a set of keyword arguments for slot-value pairs

Function Signature
````julia
find_indices(actr::ACTR; criteria...)
````
## Example
````julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
````
"""
find_indices(actr::ACTR, funs...; criteria...) = find_indices(actr.declarative.memory, funs...; criteria...)

"""
**find_indices** returns the index of first chunk that matches a set of criteria
- `chunks`: an array of chunks
- `funs`: a set of functions
- `criteria`: a set of keyword arguments for slot-value pairs

Function Signature
````julia
find_indices(actr::ACTR; criteria...)
````
## Example
````julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
````
"""
function find_indices(chunks::Array{<:Chunk,1}, funs...; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c, funs...; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

"""
**import_printing** import printing functions `print_chunk` and `print_memory`
"""
function import_printing()
    path = pathof(ACTRModels) |> dirname |> x->joinpath(x, "Utilities/")
    include(path*"Printing.jl")
end