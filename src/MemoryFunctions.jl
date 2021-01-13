"""
**baselevel** 

Computes baselevel activation according exact equation
* `d`: decay parameter
* `lags`: a vector of time lags between current time and each usage time

Function Signature
````julia 
baselevel!(actr, chunk)
````
**Function Signature**
````julia
baselevel(d, lags)
````
"""
function baselevel(d, lags)
    act = 0.0
    for t in lags
        act += t^-d
    end
    return log(act)
end

"""
**baselevel!** 

Computes baselevel activation according to the hybrid approximation
* `actr`: ACTR object
* `chunk`: a chunk

**Function Signature**
````julia 
baselevel!(actr, chunk)
````
"""
function baselevel!(actr, chunk)
    @unpack N,L,k,lags = chunk
    d = actr.parms.d
    exact = baselevel(d, lags)
    approx = 0.0
    if N > k
        tk = lags[k]
        x1 = (N - k) * (L^(1 - d) - tk^(1 - d))
        x2 = (1 - d) * (L - tk)
        approx = x1 / x2
    end
    chunk.act_bll = log(exp(exact) + approx)
    return nothing
end

"""
**baselevel!** 

Computes baselevel activation for all chunks in declarative memory
 according to the hybrid approximation
* `actr`: ACTR object

**Function Signature**
````julia 
baselevel!(actr)
````
"""
baselevel!(actr) = activation!.(actr, memory.memory)

"""
**compute_activation!* 

Computes the activation of a set of chunks
- `actr`: actr object
- `chunks`: a set of chunks.
- `cur_time`: current time. Default 0.0 used when bll is false
- `request`: optional NamedTuple for retrieval request

**Function Signature**
````julia 
compute_activation!(actr::AbstractACTR, chunks::Vector{<:Chunk}, cur_time::Float64=0.0; request...)
````
"""
function compute_activation!(actr::AbstractACTR, chunks::Vector{<:Chunk}, cur_time::Float64=0.0; request...)
    @unpack sa,noise = actr.parms
    if sa
        # Cache denoms in spreading activation for effeciency
        spreading_activation!(actr)
    end
    # compute activation for each chunk
    for chunk in chunks
        activation!(actr, chunk, cur_time; request...)
    end
    return nothing
end

"""
**compute_activation!**

Computes the activation of a chunk
- `actr`: actr object
- `chunk`: a chunk
- `cur_time`: current time. Default 0.0 used when bll is false
- `request`: optional keyword arguments for retrieval request

**Function Signature**
````julia 
compute_activation!(actr, chunk::Chunk, cur_time=0.0; request...)
````
"""
compute_activation!(actr, chunk::Chunk, cur_time=0.0; request...) = compute_activation!(actr, [chunk], cur_time; request...)

"""
**compute_activation!** 

Computes the activation for all declarative memory
- `actr`: actr object
- `cur_time`: current time. Default 0.0 used when bll is false
- `request`: optional keyword arguments for retrieval request

**Function Signature**
````julia 
compute_activation!(actr::AbstractACTR, cur_time::Float64=0.0; request...)
````
"""
compute_activation!(actr::AbstractACTR, cur_time::Float64=0.0; request...) = compute_activation!(actr, actr.declarative.memory, cur_time; request...)

"""
**activation!** 

Computes activation for a given chunk
- `actr`: ACT-R object
- `chunk`: chunk object
- `cur_time`: current time, default = 0
- `request`: optional keyword arguments for retrieval request

**Function Signature**
````julia
activation!(actr, chunk::Chunk, cur_time=0.0; request...)
````
"""
function activation!(actr, chunk::Chunk, cur_time=0.0; request...)
    memory = actr.declarative
    @unpack bll,mmp,sa,noise,blc,τ = actr.parms
    reset_activation!(chunk)
    chunk.act_blc = blc + chunk.bl
    if bll
        update_lags!(chunk, cur_time)
        baselevel!(actr, chunk)
    end
    if mmp
        partial_matching!(actr, chunk; request...)
    end
    if sa
        spreading_activation!(actr, chunk)
    end
    if noise
        add_noise!(actr, chunk)
    end
    total_activation!(chunk)
    return nothing
end

function reset_activation!(chunk)
    a = chunk.act
    chunk.act_blc = zero(a)
    chunk.act_bll = zero(a)
    chunk.act_pm = zero(a)
    chunk.act_sa = zero(a)
    chunk.act_noise = zero(a)
    chunk.act = zero(a)
end

"""
**total_activation!** 

Sums activation across all components
- `chunk`: chunk object

**Function Signature**
````julia
total_activation!(chunk)
````
"""
function total_activation!(chunk)
    chunk.act = chunk.act_blc + chunk.act_bll - chunk.act_pm +
        chunk.act_sa + chunk.act_noise
    return nothing
end

function add_noise!(actr, chunk)
    @unpack τ,s = actr.parms
    σ = s * pi / sqrt(3)
    chunk.act_noise = rand(Normal(0, σ))
    actr.parms.τ′ = rand(Normal(τ, σ))
    return nothing
end

function add_noise!(actr)
    @unpack τ,s = actr.parms
    σ = s * pi / sqrt(3)
    actr.parms.τ′ = rand(Normal(τ, σ))
    nothing
end

"""
**partial_matching!** 

Computes activation for partial matching component
- `actr`: an ACTR object
- `chunk`: a chunk 
- `request...`: optional keyword arguments for retrieval request

**Function Signature**
````julia
partial_matching!(actr, chunk; request...)
````
"""
function partial_matching!(actr, chunk; request...)
    p = actr.parms.mmpFun(actr, chunk; request...)
    chunk.act_pm = p
    return nothing
end

"""
**set_noise!** 

Sets noise true or false.
* `actr`: ACTR object
* `b`: boolean value

**Function Signature**
````julia
set_noise!(actr::AbstractACTR, b)
````
"""
function set_noise!(actr, b)
    actr.parms.noise = b
end

"""
**spreading_activation** 

Computes the spreading activation for a given chunk
* `actr`: actr object or declarative memory object
* `chunk`: the chunk for which spreading activation is computed

**Function Signature**
````julia
spreading_activation!(actr, chunk)
````
"""
function spreading_activation!(actr, chunk)
    imaginal = actr.imaginal
    isempty(imaginal.buffer) ? (return nothing) : nothing 
    w = compute_weights(imaginal)
    r = 0.0; sa = 0.0; γ = actr.parms.γ
    slots = imaginal.buffer[1].slots
    denoms = imaginal.denoms
    for (v,d) in zip(slots, denoms)
        num = count_values(chunk, v)
        fan = num / (d + 1)
        r = fan == 0 ? 0.0 : γ + log(fan)
        sa += w * r
    end
    chunk.act_sa = sa# max(0.0,sa)#causes errors in gradient
    return nothing
end

# Caches the denominator of spreading activation
function spreading_activation!(actr)
    @unpack imaginal,declarative = actr
    isempty(imaginal.buffer) ? (return nothing) : nothing 
    slots = imaginal.buffer[1].slots
    denoms = fill(0, length(slots))
    for (i,v) in enumerate(slots)
        denoms[i] = compute_denom(declarative, v)
    end
    imaginal.denoms = denoms
    return nothing
end

function compute_weights(mod)
    return mod.ω / length(mod.buffer[1].slots)
end

function compute_denom(memory, value)
    denom = 0
    for c in memory.memory
        denom += count_values(c, value)
    end
    return denom
end

function count_values(chunk, value)
    return count(x -> x == value, values(chunk.slots))
end

"""
**update_recent** 

Adds a new timestamp to chunk and removes oldest timestamp if
length equals k.
* `chunk`: memory chunk object
* `cur_time`: current time in seconds

**Function Signature**
````julia
update_recent!(chunk, cur_time)
````
"""
function update_recent!(chunk, cur_time)
    k = chunk.k; recent = chunk.recent
    if length(recent) == k
        pop!(recent)
    end
    pushfirst!(recent, cur_time)
    return nothing
end

"""
**retrieval_prob** 

Computes the retrieval probability of one chunk from a set of chunks defined in `target`.
* `actr`: an actr object
* `chunk`: a chunk
* `cur_time`: current time. Default 0.0 to be used when bll is false
* `request`: optional NamedTuple for retrieval request

**Function Signature**
````julia
retrieval_prob(actr::AbstractACTR, target::Array{<:Chunk,1}, cur_time=0.0; request...)
````
"""
function retrieval_prob(actr::AbstractACTR, target::Array{<:Chunk,1}, cur_time=0.0; request...)
    @unpack τ,s,noise = actr.parms
    σ = s * sqrt(2)
    chunks = retrieval_request(actr; request...)
    filter!(x -> (x ∈ chunks), target)
    isempty(target) ? (return (0.0,1.0)) : nothing
    set_noise!(actr, false)
    compute_activation!(actr, chunks, cur_time; request...)
    denom = fill(target[1].act, length(chunks) + 1)
    map!(x -> exp(x.act / σ), denom, chunks)
    denom[end] = exp(τ / σ)
    num = map(x -> exp(x.act / σ), target)
    prob = sum(num) / sum(denom)
    fail = denom[end] / sum(denom)
    set_noise!(actr, noise)
    return prob,fail
end

"""
**retrieval_prob** 

Computes the retrieval probability of retrieving a chunk.
* `actr`: an actr object
* `chunk`: a chunk
* `cur_time`: current time. Default 0.0 to be used when bll is false
* `request`: optional NamedTuple for retrieval request

**Function Signature**
````julia
retrieval_prob(actr::AbstractACTR, chunk::Chunk, cur_time=0.0; request...)
````
"""
function retrieval_prob(actr::AbstractACTR, chunk::Chunk, cur_time=0.0; request...)
    @unpack τ,s,noise = actr.parms
    σ = s * sqrt(2)
    chunks = retrieval_request(actr; request...)
    !(chunk ∈ chunks) ? (return (0.0,1.0)) : nothing
    set_noise!(actr, false)
    compute_activation!(actr, chunks, cur_time; request...)
    v = fill(chunk.act, length(chunks) + 1)
    map!(x -> exp(x.act / σ), v, chunks)
    v[end] = exp(τ / σ)
    prob = exp(chunk.act / σ) / sum(v)
    fail = v[end] / sum(v)
    set_noise!(actr, noise)
    return prob,fail
end

"""
**retrieval_probs** 

Computes the retrieval probability for each chunk matching the retrieval request.
* `actr`: an actr object
* `cur_time`: current time. Default 0.0 to be used when bll is false
* `request`: optional NamedTuple for retrieval request

**Function Signature**
````julia
retrieval_probs(actr::AbstractACTR, cur_time=0.0; request...)
````
"""
function retrieval_probs(actr::AbstractACTR, cur_time=0.0; request...)
    @unpack τ,s,γ,noise = actr.parms
    σ = s * sqrt(2)
    set_noise!(actr, false)
    chunks = retrieval_request(actr; request...)
    isempty(chunks) ? (return ([0.0],chunks)) : nothing
    compute_activation!(actr, chunks, cur_time; request...)
    v = Array{typeof(chunks[1].act),1}(undef, length(chunks) + 1)
    map!(x -> exp(x.act / σ), v, chunks)
    v[end] = exp(τ / σ)
    p = v ./ sum(v)
    set_noise!(actr, noise)
    return p,chunks
end

"""
**update_lags** 

Compute lags for each use of a chunk.
* `chunk`: a chunk
* `cur_time`: current time. Default 0.0 to be used when bll is false

**Function Signature**
````julia
update_lags!(chunk::Chunk, cur_time)
````
"""
function update_lags!(chunk::Chunk, cur_time)
    chunk.L = cur_time - chunk.time_created
    chunk.lags = cur_time .- chunk.recent
    return nothing
end

"""
**update_lags** 

Compute lags for each use of a chunk. Applies to all chunks in declarative memory.
* `actr`: an ACTR object
* `cur_time`: current time. Default 0.0 to be used when bll is false

**Function Signature**
````julia
update_lags!(actr::AbstractACTR, cur_time)
````
"""
update_lags!(actr::AbstractACTR, cur_time) = update_lags!(actr.declarative, cur_time)

"""
**update_lags** 

Compute lags for each use of a chunk. Applies to all chunks in declarative memory.
* `memory`: a declarative memory object object
* `cur_time`: current time. Default 0.0 to be used when bll is false

Function Signature
````julia
update_lags!(memory::Declarative, cur_time)
````
"""
update_lags!(memory::Declarative, cur_time) = update_lags!.(memory.memory, cur_time)

function update_chunk!(chunk, cur_time)
    update_recent!(chunk, cur_time)
    chunk.N += 1
    return nothing
end

"""
**add_chunk!** 

Adds new chunk to declarative memory or updates existing chunk with new use
* `memory`: declarative memory object
* `cur_time`: current time, default = 0.0
* `act`: optional activation value
* `slots`: optional keyword arguments corresponding to slot-value pairs, e.g. name=:Bob

**Function Signature**
````julia
add_chunk!(memory::Declarative, cur_time=0.0; act=0.0, slots...)
````
"""
function add_chunk!(memory::Declarative, cur_time=0.0; act=0.0, slots...)
    chunk = get_chunks(memory; slots...)
    if isempty(chunk)
        c = Chunk(;act=act, time_created=cur_time, recent=[cur_time], slots...)
        push!(memory.memory, c)
    else
        update_chunk!(chunk[1], cur_time)
    end
    return nothing
end

"""
**add_chunk!**

Adds a new chunk to declarative memory or updates existing chunk with new use
* `memory`: declarative memory object
* `cur_time`: current time, default = 0.0
* `slots`: optional keyword arguments corresponding to slot-value pairs, e.g. name=:Bob

**Function Signature**
````julia
add_chunk!(actr::ACTR, cur_time=0.0; request...)
````
"""
add_chunk!(actr::ACTR, cur_time=0.0; request...) = add_chunk!(actr.declarative, cur_time; request...)

"""
**get_chunks** 

Returns all chunks that matches a set criteria
* `memory`: vector of chunk objects
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
get_chunks(memory::Vector{<:Chunk}; args...)
````
"""
function get_chunks(memory::Vector{<:Chunk}; args...)
    c = filter(x -> match(x, args), memory)
    return c
end

"""
**get_chunks** 

Returns all chunks that matches a set criteria
* `memory`: vector of chunk objects
* `funs`: a list of functions
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
get_chunks(memory::Vector{<:Chunk}, funs...; args...)
````
"""
function get_chunks(memory::Vector{<:Chunk}, funs...; args...)
    c = filter(x -> match(x, funs...; args...), memory)
    return c
end

"""
**get_chunks** 

Returns all chunks that matches a set criteria
* `d`: declarative memory object
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
get_chunks(d::Declarative; args...) 
````
"""
get_chunks(d::Declarative; args...) = get_chunks(d.memory; args...)

"""
**get_chunks** 

Returns all chunks that matches a set criteria
* `a`: an ACTR Object
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
get_chunks(a::AbstractACTR; args...)
````
"""
get_chunks(a::AbstractACTR; args...) = get_chunks(a.declarative.memory; args...)

"""
**get_chunks** 

Returns all chunks that matches a set criteria
* `d`: declarative memory object
* `funs`: a list of functions
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
get_chunks(d::Declarative, funs...; args...)
````
"""
get_chunks(d::Declarative, funs...; args...) = get_chunks(d.memory, funs...; args...)

"""
**get_chunks** 

Returns all chunks that matches a set criteria
* `a`: an ACTR Object
* `funs`: a list of functions
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
get_chunks(a::AbstractACTR, funs...; args...)
````
"""
get_chunks(a::AbstractACTR, funs...; args...) = get_chunks(a.declarative.memory, funs...; args...)

"""
**first_chunk** 

Returns the first chunk in memory that matches a set of criteria
* `memory`: delcarative memory object
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
first_chunk(memory::Vector{<:Chunk}; args...)
````
"""
function first_chunk(memory::Vector{<:Chunk}; args...)
    chunk = Array{eltype(memory),1}()
    for m in memory
        if match(m, args)
            push!(chunk, m)
            return chunk
        end
    end
    return chunk
end

"""
**first_chunk** 

Returns the first chunk in memory that matches a set of criteria
* `memory`: delcarative memory object
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
first_chunk(memory::Vector{<:Chunk}; args...)
````
"""
first_chunk(d::Declarative; args...) = first_chunk(d.memory; args...)

"""
**first_chunk** 

Returns the first chunk in memory that matches a set of criteria
* `a`: an ACTR object
* `args`: optional keyword arguments corresponding to critiria for matching chunk

**Function Signature**
````julia
first_chunk(a::AbstractACTR; args...)
````
"""
first_chunk(a::AbstractACTR; args...) = first_chunk(a.declarative.memory; args...)

"""
**match** 

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.
* `chunk`: chunk object
* `request`: a NamedTuple of slot value pairs

**Function Signature**
````julia
match(chunk::Chunk, request)
````
"""
function match(chunk::Chunk, request)
    slots = chunk.slots
    for (k,v) in request
        if !(k ∈ keys(slots)) || (slots[k] != v)
            return false
        end
    end
    return true
end

"""
**match**

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.
* `chunk`: chunk object
* `f`: a list of functions such as `!=, ==`
* `request`: a NamedTuple of slot value pairs

**Function Signature**
````julia
match(chunk::Chunk, f, request)
````
"""
function match(chunk::Chunk, f, request)
    slots = chunk.slots
    i = 1
    for (k,v) in request
        if !(k ∈ keys(slots)) || !(f[i](slots[k], v))
            return false
        end
        i += 1
    end
    return true
end

"""
**match** 

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.
* `chunk`: chunk object
* `request`: a NamedTuple of slot value pairs

**Function Signature**
````julia
match(chunk::Chunk; request)
````
"""
match(chunk::Chunk; request...) = match(chunk, request)

"""
**match** 

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.
* `chunk`: chunk object
* `funs`: a list of functions such as `!=, ==`
* `request`: a NamedTuple of slot value pairs

**Function Signature**
````julia
match(chunk::Chunk, funs...; request)
````
"""
match(chunk::Chunk, funs...; request...) = match(chunk, funs, request)

"""
*get_subset* 

Returns a filtered subset of the retrieval request when partial matching is on.
By default, slot values for isa and retrieved must match exactly.
- `actr`: an ACTR object
- `request`: a list of keyword values respresenting slot-value pairs.

**Function Signature**
````julia
get_subset(actr; request...)
````
"""
function get_subset(actr; request...)
    return Iterators.filter(x -> any(s->s == x[1], actr.declarative.filtered),
    request)
end

"""
**retrieval_request** 

Returns chunks matching a retrieval request.
* `memory`: declarative memory object
* `request`: optional keyword arguments corresponding to retrieval request e.g. dog = :fiddo

**Function Signature**
````julia 
retrieval_request(actr::AbstractACTR; request...)
````
"""
function retrieval_request(actr::AbstractACTR; request...)
    @unpack mmp = actr.parms
    if !mmp
        return get_chunks(actr; request...)
    end
    c = get_subset(actr; request...)
    return get_chunks(actr; c...)
end

"""
**modify!** 

Modifies fields of an object
* `c`: an object
* `args`: optional keywords for field and values

**Function Signature**
````julia 
modify!(c; args...)
````
"""
function modify!(c; args...)
    for (k,v) in args
        setfield!(c, k, v)
    end
    return nothing
end

"""
**modify!** 

Modifies fields of NamedTupled
* `c`: a NamedTuple
* `args`: optional keywords for field and values

**Function Signature**
````julia 
modify!(c; args...)
````
"""
function modify!(c; args...)
    for (k,v) in args
        setfield!(c, k, v)
    end
    return nothing
end
function modify!(c::NamedTuple; args...)
    for (k,v) in args
        c[k][1] = v
    end
    return nothing
end

"""
**retrieve** 

Retrieves a chunk given a retrieval request
* `actr`: an ACT-R object
* `cur_time`: current time, default 0.0 (use when base level learning is false)
* `request`: optional keyword arguments representing a retrieval request, e.g. person=:bob

**Function Signature**
````julia
retrieve(actr::AbstractACTR, cur_time=0.0; request...)
````
"""
function retrieve(actr::AbstractACTR, cur_time=0.0; request...)
    memory = actr.declarative
    arr = Array{eltype(memory.memory),1}()
    chunks = retrieval_request(actr; request...)
    # add noise to threshold even if result of request is empty
    actr.parms.noise ? add_noise!(actr) : nothing 
    isempty(chunks) ? (return arr) : nothing
    compute_activation!(actr, chunks, cur_time; request...)
    τ′ = actr.parms.τ′
    best = get_max_active(chunks)
    if best[1].act >= τ′
        return best
    end
    return arr
end

"""
**get_max_active** 

Returns the chunk with maximum activation
* `chunks`: a vector of chunk objects

**Function Signature**
````julia
get_max_active(chunks)
````
"""
function get_max_active(chunks)
    a = -Inf
    mx = chunks[1]
    for c in chunks
        if c.act > a
            a = c.act
            mx = c
        end
    end
    return [mx]
end

"""
**compute_RT** 

Generates a reaction time for retrieving a chunk based
on the current activation levels of a chunk. If the vector is empty, time for a retrieval failure 
is returned
* `actr`: ACTR object
* `chunk`: a vector that is empty or contains one chunk

**Function Signature**
````julia
compute_RT(actr, chunk)
````
"""
function compute_RT(actr, chunk)
    @unpack τ′,lf = actr.parms
    if isempty(chunk)
        return lf * exp(-τ′)
    end
    return lf * exp(-chunk[1].act)
end


"""
**compute_RT** 

Generates a reaction time for retrieving a chunk based
on the current activation levels of a chunk.
* `actr`: ACTR object
* `chunk`: a chunk

**Function Signature**
````julia
compute_RT(actr, chunk)
````
"""
function compute_RT(actr, chunk::Chunk)
    @unpack lf = actr.parms
    return lf * exp(-chunk.act)
end

"""
**get_parm** 

Returns the value of a parameter
* `actr`: ACTR object
* ` p`: parameter name

**Function Signature**
````julia
get_parm(actr, p)
````
"""
function get_parm(actr, p)
    misc = actr.parms.misc
    if p in keys(misc)
        return misc[p]
    end
    return getfield(actr.parms, p)
end