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
    posterior_predictive(model, chain, n_samples::Int, f=x -> x)

Returns posterior predictive distribution and optionally applies function to samples 
    on each replication
- `model`: the data generating function of a model 
- `chain`: an MCMCChains chain object
- `n_samples`: the number of samples 
- `f`: a function that is applied to each sample from posterior predictive distribution

"""
function posterior_predictive(model, chain, n_samples::Int, f=x -> x)
    return map(x -> _posterior_predictive(model, chain, f), 1:n_samples)
end

find_index(actr::AbstractACTR; check_value=true, criteria...) = find_index(actr.declarative.memory; check_value, criteria...)

"""
    find_index(chunks::Array{<:Chunk,1}; check_value=true, criteria...)

Returns the index of first chunk that matches a set of criteria

# Arguments 

- `chunks`: an array of chunks

# Keywords

- `check_value=true`: 
- `criteria`: a set of keyword arguments for slot-value pairs


# Example
```julia
chunks = [Chunk(animal=:dog), Chunk(animal=cat)]
find_index(chunks; animal=:dog)
```
"""
function find_index(chunks::Array{<:Chunk,1}; check_value=true, criteria...)
    for (i,c) in enumerate(chunks)
        match(c; check_value, criteria...) ? (return i) : nothing
    end
    return -100
end

"""
    find_index(actr::ACTR, funs...; check_value=true, criteria...)

Returns the index of first chunk that matches a set of criteria

# Arguments

- `actr`: ACTR object
- `funs`: a set of functions

# Keywords

- `check_value=true`: 
- `criteria`: a set of keyword arguments for slot-value pairs

# Example

```julia
chunks = [Chunk(animal=:dog), Chunk(animal=cat)]
find_index(chunks; animal=:dog)
```
"""
find_index(actr::ACTR, funs...; check_value=true, criteria...) = find_index(actr.declarative.memory, funs...; check_value, criteria...)

"""
    find_index(chunks::Array{<:Chunk,1}, funs...; check_value=true, criteria...)

Returns the index of first chunk that matches a set of criteria

# Arguments

- `chunks`: an array of chunks
- `funs`: a set of functions
- `criteria`: a set of keyword arguments for slot-value pairs

# Keywords

- `check_value=true`: 
- `criteria`: a set of keyword arguments for slot-value pairs


```julia
chunks = [Chunk(animal=:dog), Chunk(animal=cat)]
find_index(chunks; animal=:dog)
```
"""
function find_index(chunks::Array{<:Chunk,1}, funs...; check_value=true, criteria...)
    for (i,c) in enumerate(chunks)
        match(c, funs...; check_value, criteria...) ? (return i) : nothing
    end
    return -100
end

"""
    find_indices(actr::ACTR; check_value = true, criteria...)

Returns the index of first chunk that matches a set of criteria

# Arguments

- `actr`: an ACTR object
- `criteria`: a set of keyword arguments for slot-value pairs
````
# Example
```julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
```
"""
find_indices(actr::ACTR; check_value = true, criteria...) = find_indices(actr.declarative.memory; check_value, criteria...)

"""
    find_indices(chunks::Array{<:Chunk,1}; check_value=true, criteria...)

Returns the index of first chunk that matches a set of criteria

# Arguments

- `chunks`: an array of chunks

# Keywords

- `check_value=true`: 
- `criteria`: a set of keyword arguments for slot-value pairs

# Example 

```julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
```
"""
function find_indices(chunks::Array{<:Chunk,1}; check_value=true, criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c; check_value, criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

"""
    find_indices(actr::ACTR, funs...; check_value=true, criteria...) 

Returns the index of first chunk that matches a set of criteria

# Arguments

- `actr`: an ACTR object
- `funs`: a set of functions

# Keywords

- `check_value=true`: 
- `criteria`: a set of keyword arguments for slot-value pairs


# Example 
```julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
```
"""
find_indices(actr::ACTR, funs...; check_value=true, criteria...) = find_indices(actr.declarative.memory, funs...; check_value, criteria...)

"""
    find_indices(chunks::Array{<:Chunk,1}, funs...; check_value=true, criteria...) 

Returns the index of first chunk that matches a set of criteria.

# Arguments

- `chunks`: an array of chunks
- `funs`: a set of functions

# Keywords

- `check_value=true`: 
- `criteria`: a set of keyword arguments for slot-value pairs


# Example

```julia
chunks = [Chunk(animal=:dog), Chunk(animal=:dog), Chunk(animal=cat)]
find_indices(chunks; animal=:dog)
```
"""
function find_indices(chunks::Array{<:Chunk,1}, funs...; check_value=true, criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c, funs...; check_value, criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

"""
    get_iconic_memory(actr)

Returns array of chunks or visual objects representing iconic memory 

# Arguments

- `actr`: an ACTR object

"""
get_iconic_memory(actr) = actr.visual_location.iconic_memory 

"""
    get_iconic_memory(actr)

Returns array of chunks or visual objects representing all visual objects
within the simulation

# Arguments

- `actr`: an ACTR object
"""
get_visicon(actr) = actr.visicon

"""
    get_buffer(actr, m)

Returns posterior predictive distribution and optionally applies function to samples 
    on each replication

# Arguments

- `actr`: an ACTR object
- `m`: name of module as a symbol

# Example
```julia
get_buffer(actr, :imaginal)
```
"""
get_buffer(actr, m) = getfield(actr, m).buffer

"""
    get_buffer(actr, m)

Returns posterior predictive distribution and optionally applies function to samples 
    on each replication

# Arguments

- `actr`: an ACTR object
- `m`: name of module as a symbol
- `v`: new value

# Example

```julia
set_buffer!(actr, :imaginal, [chunk])
```
"""
set_buffer!(actr, m, v) = getfield(actr, m).buffer = v

"""
    get_mean_activations(actr::AbstractACTR)


Returns a vector of mean activations i.e. activation without noise

# Arguments
- `actr::AbstractACTR`: an ACTR object
"""
get_mean_activations(actr::AbstractACTR) = get_mean_activations(actr.declarative)

"""
    get_mean_activations(declarative::Declarative)

Returns a vector of mean activations i.e. activation without noise

# Arguments
- `declarative::Declarative`: an Declarative memory object
"""
get_mean_activations(declarative::Declarative) = get_mean_activations(declarative.memory)

"""
    get_mean_activations(chunks::Vector{<:Chunk}) 

Returns a vector of mean activations i.e. activation without noise

# Arguments

- `chunks::Vector{<:Chunk}`: an array of chunks
"""
function get_mean_activations(chunks::Vector{<:Chunk})
    return map(x->x.act - x.act_noise, chunks)
end

"""
    get_name(actr::AbstractACTR)

Returns the name of an ACT-R model object. 

# Arguments

- `actr::AbstractACTR`: an ACTR model object
"""
function get_name(actr::AbstractACTR)
    return actr.name
end

get_time(actr::AbstractACTR) = get_time(actr.scheduler)
get_time(scheduler) = scheduler.time 

add_time!(actr::AbstractACTR, t) = add_time!(actr.scheduler, t)
add_time!(scheduler, t) = scheduler.time += t

reset_time!(actr::AbstractACTR) = reset_time!(actr.scheduler)
reset_time!(scheduler) = scheduler.time = 0.0

set_time!(actr::AbstractACTR, t) = set_time!(actr.scheduler, t)
set_time!(scheduler, t) = scheduler.time = t

rnd_time(μ) = rand(Uniform(μ * (2/3), μ * (4/3)))