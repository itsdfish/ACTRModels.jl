"""
    baselevel(d, lags)

Computes baselevel activation according exact equation.

# Arguments

- `d`: decay parameter
- `lags`: a vector of time lags between current time and each usage time
"""
function baselevel(d, lags)
    act = 0.0
    for t in lags
        act += t^-d
    end
    return log(act)
end

"""
    baselevel(d, chunk)

Computes baselevel activation according exact equation.

# Arguments

- `actr`: an `ACTR` model object
- `chunk`: a chunk
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
    baselevel!(actr)

Computes baselevel activation for all chunks according exact equation.

# Arguments

- `actr`: an `ACTR` model object
"""
baselevel!(actr) = activation!.(actr, memory.memory)

"""
    compute_activation!(actr::AbstractACTR, chunks::Vector{<:Chunk}, cur_time::Float64=0.0; request...) 

Computes the activation of a vector of chunks

# Arguments

- `actr::AbstractACTR`: an `ACTR` object
- `chunks::Vector{<:Chunk}`: a vector of chunks.
- `cur_time::Float64=0.0`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function compute_activation!(actr::AbstractACTR, chunks::Vector{<:Chunk}, cur_time::Float64=0.0; request...)
    @unpack sa = actr.parms
    sa ? cache_denomitors(actr) : nothing
    # compute activation for each chunk
    for chunk in chunks
        activation!(actr, chunk, cur_time; request...)
    end
    return nothing
end

"""
    compute_activation!(actr, chunk::Chunk, cur_time=0.0; request...) 

Computes the activation of a chunk

# Arguments

- `actr`: actr object
- `chunk::Chunk`: a chunk.
- `cur_time=0`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
compute_activation!(actr, chunk::Chunk, cur_time=0.0; request...) = compute_activation!(actr, [chunk], cur_time; request...)

"""
    compute_activation!(actr::AbstractACTR, cur_time::Float64=0.0; request...)

Computes the activation of all chunks in declarative memory

# Arguments

- `actr::AbstractACTR`: an `ACTR` object
- `cur_time::Float64=0.0`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
compute_activation!(actr::AbstractACTR, cur_time::Float64=0.0; request...) = compute_activation!(actr, actr.declarative.memory, cur_time; request...)

"""
    activation!(actr, chunk::Chunk, cur_time=0.0; request...) 

Computes the activation of a chunk

# Arguments

- `actr`: an `ACTR` object
- `chunk::Chunk`: a chunk.
- `cur_time=0`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function activation!(actr, chunk::Chunk, cur_time=0.0; request...)
    memory = actr.declarative
    @unpack sa_fun,bll,mmp,sa,noise,blc,τ = actr.parms
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
        sa_fun(actr, chunk)
    end
    if noise
        add_noise!(actr, chunk)
    end
    total_activation!(chunk)
    return nothing
end

function reset_activation!(chunk)
    a = chunk.act
    chunk.act_mean = zero(a)
    chunk.act_blc = zero(a)
    chunk.act_bll = zero(a)
    chunk.act_pm = zero(a)
    chunk.act_sa = zero(a)
    chunk.act_noise = zero(a)
    chunk.act = zero(a)
end

"""
    total_activation!(chunk)

Assigns sum of all components to of activation to `chunk.act`.

# Arguments

- `chunk`: a chunk object
"""
function total_activation!(chunk)
    chunk.act_mean = chunk.act_blc + chunk.act_bll - chunk.act_pm +
        chunk.act_sa 
    chunk.act = chunk.act_mean + + chunk.act_noise
    return nothing
end

function add_noise!(actr, chunk)
    @unpack τ,s = actr.parms
    σ = s * pi / sqrt(3)
    chunk.act_noise = rand(Normal(0, σ))
    return nothing
end

function add_noise!(actr)
    @unpack τ,s = actr.parms
    σ = s * pi / sqrt(3)
    actr.parms.τ′ = rand(Normal(τ, σ))
    nothing
end

"""
    partial_matching!(actr, chunk; request...)

Computes activation for partial matching component

# Arguments

- `actr`: an ACTR object
- `chunk`: a chunk 

# Keywords

- `request...`: optional keyword arguments for retrieval request
"""
function partial_matching!(actr, chunk; request...)
    p = actr.parms.mmpFun(actr, chunk; request...)
    chunk.act_pm = p
    return nothing
end

"""
    set_noise!(actr::AbstractACTR, b)

Sets noise true or false.

# Arguments

- `actr`: ACTR object
- `b`: boolean value
"""
function set_noise!(actr, b)
    actr.parms.noise = b
end

"""
    spreading_activation!(actr, chunk) 

Computes the spreading activation for a given chunk

# Arguments

- `actr`: an `ACTR` oject
- `chunk`: the chunk for which spreading activation is computed
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
    chunk.act_sa = sa
    return nothing
end

"""
    cache_denomitors(actr) 

Caches denominator of spreading activation calculations

# Arguments

- `actr`: an `ACTR` oject
"""
function cache_denomitors(actr)
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
    update_recent!(chunk, cur_time)

Adds a new timestamp to chunk and removes oldest timestamp if
length equals k.

# Arguments

* `chunk`: memory chunk object
* `cur_time`: current simulated time in seconds
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
    retrieval_prob(actr::AbstractACTR, target::Array{<:Chunk,1}, cur_time=0.0; request...)

Computes the retrieval probability of one chunk from a set of chunks defined in `target`.
Retrieval probability is computed with the softmax approximation.

# Arguments

* `actr::AbstractACTR`: an actr object
* `target::Array{<:Chunk,1}`: a vector chunks in the numerator of the softmax function
* `cur_time=0.0`: current time in seconds

# Keywords

* `request...`: optional keywords for the retrieval request
"""
function retrieval_prob(actr::AbstractACTR, target::Array{<:Chunk,1}, cur_time=0.0; request...)
    @unpack τ,s = actr.parms
    σ = s * sqrt(2)
    chunks = retrieval_request(actr; request...)
    filter!(x -> (x ∈ chunks), target)
    isempty(target) ? (return (0.0,1.0)) : nothing
    compute_activation!(actr, chunks, cur_time; request...)
    denom = fill(target[1].act_mean, length(chunks) + 1)
    map!(x -> exp(x.act_mean / σ), denom, chunks)
    denom[end] = exp(τ / σ)
    num = map(x -> exp(x.act / σ), target)
    prob = sum(num) / sum(denom)
    fail = denom[end] / sum(denom)
    return prob,fail
end

"""
    retrieval_prob(actr::AbstractACTR, chunk::Chunk, cur_time=0.0; request...)

Uses the softmax approximation to compute the retrieval probability of retrieving a chunk.

# Arguments

- `actr::AbstractACTR`: an ACT-R object
- `chunk::Chunk`: a chunk
- `cur_time=0.0`: current simulated time in seconds

# Keywords

- `request...`: optional keyword pairs representing a retrieval request
"""
function retrieval_prob(actr::AbstractACTR, chunk::Chunk, cur_time=0.0; request...)
    @unpack τ,s = actr.parms
    σ = s * sqrt(2)
    chunks = retrieval_request(actr; request...)
    !(chunk ∈ chunks) ? (return (0.0,1.0)) : nothing
    compute_activation!(actr, chunks, cur_time; request...)
    v = fill(chunk.act_mean, length(chunks) + 1)
    map!(x -> exp(x.act_mean / σ), v, chunks)
    v[end] = exp(τ / σ)
    prob = exp(chunk.act_mean / σ) / sum(v)
    fail = v[end] / sum(v)
    return prob,fail
end

"""
    retrieval_probs(actr::AbstractACTR, cur_time=0.0; request...)

Computes the retrieval probability for each chunk matching the retrieval request.

# Arguments

- `actr::AbstractACTR`: an actr object
- `cur_time`: current simulated time in seconds

# Keywords

- `request...`: optional keyword pairs representing a retrieval request
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
    update_lags!(chunk::Chunk, cur_time)

Compute lags for each use of a chunk.

# Arguments

- `chunk::Chunks`: a chunk
- `cur_time`: current simulated time in seconds.

"""
function update_lags!(chunk::Chunk, cur_time)
    chunk.L = cur_time - chunk.time_created
    chunk.lags = cur_time .- chunk.recent
    return nothing
end

"""
    update_lags!(actr::AbstractACTR, cur_time)

Compute lags for each use of a chunk. Applies to all chunks in declarative memory.

# Arguments

- `actr::AbstractACTR`: an ACTR object
- `cur_time`: current simulated time in seconds
"""
update_lags!(actr::AbstractACTR, cur_time) = update_lags!(actr.declarative, cur_time)

"""
    update_lags!(memory::Declarative, cur_time)

Compute lags for each use of a chunk. Applies to all chunks in declarative memory.

# Arguments

- `memory::Declarative`: a declarative memory object object
- `cur_time`: current simulated time in seconds
"""
update_lags!(memory::Declarative, cur_time) = update_lags!.(memory.memory, cur_time)

"""
    update_chunk!(chunk, cur_time)

Increments number of uses and adds `cur_time` as the most recent time of use.

# Arguments

- `chunk`: a chunk object 
- `cur_time': current simulated time in seconds 
"""
function update_chunk!(chunk, cur_time)
    update_recent!(chunk, cur_time)
    chunk.N += 1
    return nothing
end

"""
    add_chunk!(memory::Declarative, cur_time=0.0; act=0.0, slots...)

Adds new chunk to declarative memory or updates existing chunk with new use

# Arguments 

- `memory::Declarative`: declarative memory object
- `cur_time=0.0`: current simulated time in seconds
- `bl=0.0`: baselevel constant for new/updated chunk

# Keywords

- `slots...`: optional keyword arguments corresponding to slot-value pairs, e.g. name=:Bob
"""
function add_chunk!(memory::Declarative, cur_time=0.0; bl=0.0, slots...)
    chunk = get_chunks(memory; slots...)
    if isempty(chunk)
        c = Chunk(;bl, time_created=cur_time, recent=[cur_time], slots...)
        push!(memory.memory, c)
    else
        update_chunk!(chunk[1], cur_time)
    end
    return nothing
end

"""
    add_chunk!(actr::AbstractACTR, cur_time=0.0; slots...)

Adds new chunk to declarative memory or updates existing chunk with new use

# Arguments 

- `actr::AbstractACTR`: an ACT-R model object
- `cur_time=0.0`: current simulated time in seconds

# Keywords

- `slots...`: optional keyword arguments corresponding to slot-value pairs, e.g. name=:Bob
"""
add_chunk!(actr::AbstractACTR, cur_time=0.0; slots...) = add_chunk!(actr.declarative, cur_time; slots...)

"""
    get_chunks(memory::Vector{<:Chunk}; args...)

Returns all chunks that matches a set criteria.

# Arguments

- `memory::Vector{<:Chunk}`: vector of chunk objects

# Keywords

-`criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function get_chunks(memory::Vector{<:Chunk}; criteria...)
    c = filter(x -> match(x, criteria), memory)
    return c
end

"""
    get_chunks(memory::Vector{<:Chunk}, funs...; criteria...)

Returns all chunks that matches a set `criteria` which are evaluted according to the list of functions in `funs`.

# Arguments 

* `memory::Vector{<:Chunk}`: vector of chunk objects
* `funs...`: a list of functions

# Keywords

* `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function get_chunks(memory::Vector{<:Chunk}, funs...; criteria...)
    c = filter(x -> match(x, funs...; criteria...), memory)
    return c
end

"""
    get_chunks(d::Declarative; criteria...)

Returns all chunks that matches a set criteria.

# Arguments

- `d::Declarative`: declarative memory object

# Keywords

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(d::Declarative; criteria...) = get_chunks(d.memory; criteria...)

"""
    get_chunks(actr::AbstractACTR; )

Returns all chunks that matches a set criteria

# Arguments

* `actr::AbstractACTR`: an ACTR Object

#Keywords

* `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(actr::AbstractACTR; criteria...) = get_chunks(actr.declarative.memory; criteria...)

"""
    get_chunks(d::Declarative, funs...; criteria...)

Returns all chunks that matches a set criteria using `funs...` as matching functions

# Arguments

* `d::Declarative`: declarative memory object
* `funs...`: a list of functions

# Keywords

* `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(d::Declarative, funs...; criteria...) = get_chunks(d.memory, funs...; criteria...)

"""
    get_chunks(actr::AbstractACTR, funs...; criteria...)

Returns all chunks that matches a set criteria using `funs...` as matching functions.

# Arguments

* `actr::AbstractACTR`: an ACT-R model object
* `funs...`: a list of functions

# Keywords

* `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(actr::AbstractACTR, funs...; criteria...) = get_chunks(actr.declarative.memory, funs...; criteria...)

"""
    first_chunk(memory::Vector{<:Chunk}; criteria...)

Returns the first chunk in memory that matches a set of criteria

# Arguments

* `memory::Vector{<:Chunk}`: a vector of chunks 

# Keywords

* `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function first_chunk(memory::Vector{<:Chunk}; criteria...)
    chunk = Array{eltype(memory),1}()
    for m in memory
        if match(m, criteria)
            push!(chunk, m)
            return chunk
        end
    end
    return chunk
end

"""
    first_chunk(d::Declarative; criteria...)

Returns the first chunk in memory that matches a set of criteria

# Arguments

* `d::Declarative`: a declarative memory object

# Keywords

* `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
first_chunk(d::Declarative; criteria...) = first_chunk(d.memory; criteria...)

"""
    first_chunk(a::AbstractACTR; criteria...)

Returns the first chunk in memory that matches a set of criteria

# Arguments

* `actr::AbstractACTR`: an ACT-R model object

# Keywords

* `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
first_chunk(actr::AbstractACTR; criteria...) = first_chunk(actr.declarative.memory; criteria...)

"""
    match(chunk::Chunk, request)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

# Arguments

- `chunk::Chunk`: chunk object
- `request`: a NamedTuple of slot value pairs
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
    match(chunk::Chunk, f, request)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

# Arguments

- `chunk`: a chunk object
- `f`: a list of functions such as `!=, ==`
- `request`: a NamedTuple of slot value pairs
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
    match(chunk::Chunk; request...)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

# Arguments

- `chunk::Chunk`: a chunk object

# Keywords

- `request...`: optional keyword arguments corresponding to critiria for matching chunk
"""
match(chunk::Chunk; request...) = match(chunk, request)

"""
    match(chunk::Chunk, funs...; request...)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

* `chunk`: chunk object
* `funs...`: a list of functions such as `!=, ==`
* `request...`: a NamedTuple of slot value pairs
"""
match(chunk::Chunk, funs...; request...) = match(chunk, funs, request)

"""
    get_subset(actr; request...)

Returns a filtered subset of the retrieval request when partial matching is on.
By default, slot values for isa and retrieved must match exactly.

# Arguments

- `actr`: an ACTR object

# Keywords

- `request...`: an option set of keyword arguments corresponding to a retrieval request.
"""
function get_subset(actr; request...)
    return Iterators.filter(x -> any(s->s == x[1], actr.declarative.filtered),
    request)
end

"""
    retrieval_request(actr::AbstractACTR; request...)

Returns chunks matching a retrieval request.

# Arguments

- `memory`: declarative memory object

# Keywords

- `request...`: optional keyword arguments corresponding to retrieval request e.g. dog = :fiddo
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
    modify!(c; args...) 

Modifies fields of an object

# Arguments

* `c`: an object

# Keywords

* `args...`: optional keywords for field and values
"""
function modify!(c; args...)
    for (k,v) in args
        setfield!(c, k, v)
    end
    return nothing
end

"""
    modify!(c::NamedTuple; args...)

Modifies fields of NamedTuple

# Arguments

* `c`: a NamedTuple

# Keywords

* `args`: optional keywords for field and values
"""
function modify!(c::NamedTuple; args...)
    for (k,v) in args
        c[k][1] = v
    end
    return nothing
end

"""
    retrieve(actr::AbstractACTR, cur_time=0.0; request...)

Retrieves a chunk given a retrieval request

# Arguments 

- `actr`: an ACT-R object
- `cur_time=0.0`: current simulated time in seconds

# Keywords

* `request...`: optional keyword arguments representing a retrieval request, e.g. person=:bob
"""
function retrieve(actr::AbstractACTR, cur_time=0.0; request...)
    @unpack declarative,parms = actr
    arr = Array{eltype(declarative.memory),1}()
    chunks = retrieval_request(actr; request...)
    # add noise to threshold even if result of request is empty
    actr.parms.noise ? add_noise!(actr) : (parms.τ′ = parms.τ)
    isempty(chunks) ? (return arr) : nothing
    compute_activation!(actr, chunks, cur_time; request...)
    best = get_max_active(chunks)
    if best[1].act >= parms.τ′
        return best
    end
    return arr
end

"""
    get_max_active(chunks)

Returns the chunk with maximum activation

# Arguments

* `chunks`: a vector of chunk objects
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


Generates a reaction time for retrieving a chunk based
on the current activation levels of a chunk. If the vector is empty, time for a retrieval failure 
is returned

# Arguments

* `actr`: ACTR object
* `chunk`: a vector that is empty or contains one chunk
"""
function compute_RT(actr, chunk)
    @unpack τ′,lf = actr.parms
    if isempty(chunk)
        return lf * exp(-τ′)
    end
    return lf * exp(-chunk[1].act)
end


"""
    compute_RT(actr, chunk)

Generates a reaction time for retrieving a chunk based
on the current activation levels of a chunk.

# Arguments

* `actr`: ACTR object
* `chunk`: a chunk
"""
function compute_RT(actr, chunk::Chunk)
    @unpack lf = actr.parms
    return lf * exp(-chunk.act)
end

"""
    get_parm(actr, p)

Returns the value of a parameter

# Arguments

* `actr`: ACTR object
* ` p`: parameter name
"""
function get_parm(actr, p)
    misc = actr.parms.misc
    if p in keys(misc)
        return misc[p]
    end
    return getfield(actr.parms, p)
end