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
    baselevel!(N, L, k, lags, d)

Computes baselevel activation with hybrid approximation.

# Arguments

- `N`: the number of times the chunk was used 
- `L`: lifetime of chunk in seconds 
- `k`: number of timestaps tracked
- `lags`: time since last use for each k
- `d`: decay rate 
"""
function baselevel!(N, L, k, lags, d)
    exact = baselevel(d, lags)
    approx = 0.0
    if N > k
        tk = lags[k]
        x1 = (N - k) * (L^(1 - d) - tk^(1 - d))
        x2 = (1 - d) * max(L - tk, 0.001)
        approx = x1 / x2
    end
    return log(exp(exact) + approx)
end

"""
    baselevel!(actr, chunk) 

Computes baselevel activation with hybrid approximation.

# Arguments

- `actr`: an `ACTR` model object
- `chunk`: a chunk
"""
function baselevel!(actr::AbstractACTR, chunk::AbstractChunk)
    (; N, L, k, lags) = chunk
    d = actr.parms.d
    chunk.act_bll = baselevel!(N, L, k, lags, d)
    return nothing
end

"""
    baselevel!(actr)

Computes baselevel activation with hybrid approximation.

# Arguments

- `actr`: an `ACTR` model object
"""
baselevel!(actr::AbstractACTR) = activation!.(actr, memory.memory)

"""
    compute_activation!(actr::AbstractACTR, chunks::Vector{<:Chunk}; request...) 

Computes the activation of a vector of chunks. By default, current time is computed with `get_time`.

# Arguments

- `actr::AbstractACTR`: an `ACTR` object
- `chunks::Vector{<:Chunk}`: a vector of chunks.

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function compute_activation!(
    actr::AbstractACTR,
    chunks::Vector{<:AbstractChunk};
    funs = (),
    request...
)
    return compute_activation!(actr, chunks, get_time(actr); funs, request...)
end

"""
    compute_activation!(actr::AbstractACTR, chunks::Vector{<:Chunk}, cur_time::Float64; request...)

Computes the activation of a vector of chunks

# Arguments

- `actr::AbstractACTR`: an `ACTR` object
- `chunks::Vector{<:Chunk}`: a vector of chunks.
- `cur_time::Float64`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function compute_activation!(
    actr::AbstractACTR,
    chunks::Vector{<:AbstractChunk},
    cur_time::Float64;
    funs = (),
    request...
)
    (; sa) = actr.parms
    sa ? cache_denomitors(actr) : nothing
    # compute activation for each chunk
    for chunk in chunks
        activation!(actr, chunk, cur_time; funs, request...)
    end
    return nothing
end
"""
    compute_activation!(actr, chunk::AbstractChunk; request...) 

Computes the activation of a chunk. By default, current time is computed 
with `get_time`.

# Arguments

- `actr`: actr object
- `chunk::AbstractChunk`: a chunk.

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function compute_activation!(
    actr::AbstractACTR,
    chunk::AbstractChunk;
    funs = (),
    request...
)
    return compute_activation!(actr, chunk, get_time(actr); funs, request...)
end

"""
    compute_activation!(actr, chunk::AbstractChunk, cur_time; request...) 

Computes the activation of a chunk

# Arguments

- `actr`: actr object
- `chunk::AbstractChunk`: a chunk.
- `cur_time`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
compute_activation!(actr::AbstractACTR, chunk::AbstractChunk, cur_time; request...) =
    compute_activation!(actr, [chunk], cur_time; request...)

"""
    compute_activation!(actr::AbstractACTR; request...)

Computes the activation of all chunks in declarative memory. By default, current time is computed
with `get_time`.

# Arguments

- `actr::AbstractACTR`: an `ACTR` object

# Keywords

- `request...`: optional keywords for the retrieval request
"""
compute_activation!(actr::AbstractACTR; funs = (), request...) =
    compute_activation!(actr, actr.declarative.memory, get_time(actr); funs, request...)

"""
    compute_activation!(actr::AbstractACTR, cur_time::Float64; request...)

Computes the activation of all chunks in declarative memory

# Arguments

- `actr::AbstractACTR`: an `ACTR` object
- `cur_time`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
compute_activation!(actr::AbstractACTR, cur_time::Float64; funs = (), request...) =
    compute_activation!(actr, actr.declarative.memory, cur_time; funs, request...)

"""
    activation!(actr, chunk::AbstractChunk, cur_time; request...) 

Computes the activation of a chunk

# Arguments

- `actr`: an `ACTR` object
- `chunk::AbstractChunk`: a chunk.
- `cur_time`: current simulated time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function activation!(
    actr::AbstractACTR,
    chunk::AbstractChunk,
    cur_time = 0.0;
    funs = (),
    request...
)
    memory = actr.declarative
    (; sa_fun, bll, mmp, sa, noise, blc, τ) = actr.parms
    reset_activation!(chunk)
    chunk.act_blc = blc + chunk.bl
    if bll
        update_lags!(chunk, cur_time)
        baselevel!(actr, chunk)
    end
    if mmp
        _funs = isempty(funs) ? fill(==, length(request)) : funs
        partial_matching!(actr, chunk; funs = _funs, request...)
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
    return chunk.act = zero(a)
end

"""
    total_activation!(chunk)

Assigns sum of all components to of activation to `chunk.act`.

# Arguments

- `chunk`: a chunk object
"""
function total_activation!(chunk::AbstractChunk)
    chunk.act_mean = chunk.act_blc + chunk.act_bll - chunk.act_pm + chunk.act_sa
    chunk.act = chunk.act_mean + chunk.act_noise
    return nothing
end

function add_noise!(actr::AbstractACTR, chunk)
    (; τ, s) = actr.parms
    σ = s * pi / sqrt(3)
    chunk.act_noise = rand(actr.rng, Normal(0, σ))
    return nothing
end

function add_noise!(actr::AbstractACTR)
    (; τ, s) = actr.parms
    σ = s * pi / sqrt(3)
    actr.parms.τ′ = rand(actr.rng, Normal(τ, σ))
    return nothing
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
function partial_matching!(actr::AbstractACTR, chunk::AbstractChunk; funs, request...)
    slots = chunk.slots
    p = 0.0
    δ = actr.parms.δ
    i = 1
    for (k, v) in request
        dissim = actr.parms.dissim_func(k, slots[k], v, funs[i])
        p += δ * dissim
        i += 1
    end
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
function set_noise!(actr::AbstractACTR, b)
    return actr.parms.noise = b
end

"""
    spreading_activation!(actr, chunk) 

Computes the spreading activation for a given chunk

# Arguments

- `actr`: an `ACTR` oject
- `chunk`: the chunk for which spreading activation is computed
"""
function spreading_activation!(actr::AbstractACTR, chunk::AbstractChunk)
    (; γ, ω) = actr.parms
    imaginal = actr.imaginal
    isempty(imaginal.buffer) ? (return nothing) : nothing
    w = compute_weights(imaginal, ω)
    r = zero(γ)
    sa = zero(γ)
    slots = imaginal.buffer[1].slots
    denoms = imaginal.denoms
    for (v, d) in zip(slots, denoms)
        num = count_values(chunk, v)
        fan = num / (d + 1)
        r = fan == 0 ? zero(γ) : γ + log(fan)
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
function cache_denomitors(actr::AbstractACTR)
    (; imaginal, declarative) = actr
    isempty(imaginal.buffer) ? (return nothing) : nothing
    slots = imaginal.buffer[1].slots
    denoms = fill(0, length(slots))
    for (i, v) in enumerate(slots)
        denoms[i] = compute_denom(declarative, v)
    end
    imaginal.denoms = denoms
    return nothing
end

function compute_weights(mod, ω)
    return ω / length(mod.buffer[1].slots)
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
    update_recent!(actr, chunk)

Adds a new timestamp to chunk and removes oldest timestamp if
length equals k. By default, current time is computed with `get_time`.

# Arguments
- `actr`: an ACT-R model object 
- `chunk`: memory chunk object
"""
function update_recent!(actr::AbstractACTR, chunk)
    return update_recent!(chunk, get_time(actr))
end

"""
    update_recent!(chunk, cur_time)

Adds a new timestamp to chunk and removes oldest timestamp if
length equals k.

# Arguments

* `chunk`: memory chunk object
* `cur_time`: current simulated time in seconds
"""
function update_recent!(chunk::AbstractChunk, cur_time)
    k = chunk.k
    recent = chunk.recent
    if length(recent) == k
        pop!(recent)
    end
    pushfirst!(recent, cur_time)
    return nothing
end

"""
    retrieval_prob(actr::AbstractACTR, target::Array{<:Chunk,1}; request...)    

Uses the softmax approximation to compute the retrieval probability of retrieving a chunk.
By default, current time is computed from `get_time`.

# Arguments

- `actr::AbstractACTR`: an ACT-R object
- `target::Array{<:Chunk,1}`: a vector chunks in the numerator of the softmax function

# Keywords

- `request...`: optional keyword pairs representing a retrieval request
"""
function retrieval_prob(actr::AbstractACTR, target::Array{<:AbstractChunk, 1}; request...)
    return retrieval_prob(actr, target, get_time(actr); request...)
end

"""
    retrieval_prob(actr::AbstractACTR, target::Array{<:Chunk,1}, cur_time; request...)

Computes the retrieval probability of one chunk from a set of chunks defined in `target`.
Retrieval probability is computed with the softmax approximation.

# Arguments

- `actr::AbstractACTR`: an actr object
- `target::Array{<:Chunk,1}`: a vector chunks in the numerator of the softmax function
- `cur_time`: current time in seconds

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function retrieval_prob(
    actr::AbstractACTR,
    target::Array{<:AbstractChunk, 1},
    cur_time;
    funs = (),
    request...
)
    (; τ, s, noise) = actr.parms
    σ = s * sqrt(2)
    _funs = isempty(funs) ? fill(==, length(request)) : funs
    chunks = retrieval_request(actr; funs = _funs, request...)
    filter!(x -> (x ∈ chunks), target)
    isempty(target) ? (return (0.0, 1.0)) : nothing
    set_noise!(actr, false)
    compute_activation!(actr, chunks, cur_time; funs = _funs, request...)
    set_noise!(actr, noise)
    denom = fill(target[1].act_mean, length(chunks) + 1)
    map!(x -> exp(x.act_mean / σ), denom, chunks)
    denom[end] = exp(τ / σ)
    num = map(x -> exp(x.act_mean / σ), target)
    prob = sum(num) / sum(denom)
    fail = denom[end] / sum(denom)
    return prob, fail
end

"""
    retrieval_prob(actr::AbstractACTR, chunk::AbstractChunk; request...)

Uses the softmax approximation to compute the retrieval probability of retrieving a chunk.
By default, current time is computed from `get_time`.

# Arguments

- `actr::AbstractACTR`: an ACT-R object
- `chunk::AbstractChunk`: a chunk

# Keywords

- `request...`: optional keyword pairs representing a retrieval request
"""
function retrieval_prob(actr::AbstractACTR, chunk::AbstractChunk; funs = (), request...)
    return retrieval_prob(actr, chunk, get_time(actr); funs, request...)
end

"""
    retrieval_prob(actr::AbstractACTR, chunk::AbstractChunk, cur_time=0.0; request...)

Uses the softmax approximation to compute the retrieval probability of retrieving a chunk.

# Arguments

- `actr::AbstractACTR`: an ACT-R object
- `chunk::AbstractChunk`: a chunk
- `cur_time`: current simulated time in seconds

# Keywords

- `request...`: optional keyword pairs representing a retrieval request
"""
function retrieval_prob(
    actr::AbstractACTR,
    chunk::AbstractChunk,
    cur_time;
    funs = (),
    request...
)
    (; τ, s, noise) = actr.parms
    σ = s * sqrt(2)
    _funs = isempty(funs) ? fill(==, length(request)) : funs
    chunks = retrieval_request(actr; funs = _funs, request...)
    !(chunk ∈ chunks) ? (return (0.0, 1.0)) : nothing
    set_noise!(actr, false)
    compute_activation!(actr, chunks, cur_time; funs = _funs, request...)
    set_noise!(actr, noise)
    v = fill(chunk.act_mean, length(chunks) + 1)
    map!(x -> exp(x.act_mean / σ), v, chunks)
    v[end] = exp(τ / σ)
    prob = exp(chunk.act_mean / σ) / sum(v)
    fail = v[end] / sum(v)
    return prob, fail
end

"""
    retrieval_probs(actr::AbstractACTR; request...)

Computes the retrieval probability for each chunk matching the retrieval request. By default,
current time is computed from `get_time`. 

# Arguments

- `actr::AbstractACTR`: an actr object

# Keywords

- `request...`: optional keyword pairs representing a retrieval request
"""

function retrieval_probs(actr::AbstractACTR; funs = (), request...)
    return retrieval_probs(actr, get_time(actr); funs = (), request...)
end

"""
    retrieval_probs(actr::AbstractACTR, cur_time; request...)

Computes the retrieval probability for each chunk matching the retrieval request.

# Arguments

- `actr::AbstractACTR`: an actr object
- `cur_time`: current simulated time in seconds

# Keywords

- `request...`: optional keyword pairs representing a retrieval request
"""
function retrieval_probs(actr::AbstractACTR, cur_time; funs = (), request...)
    (; τ, s, noise) = actr.parms
    σ = s * sqrt(2)
    _funs = isempty(funs) ? fill(==, length(request)) : funs
    chunks = retrieval_request(actr; funs = _funs, request...)
    isempty(chunks) ? (return ([0.0], chunks)) : nothing
    set_noise!(actr, false)
    compute_activation!(actr, chunks, cur_time; funs = _funs, request...)
    set_noise!(actr, noise)
    v = Array{typeof(chunks[1].act), 1}(undef, length(chunks) + 1)
    map!(x -> exp(x.act_mean / σ), v, chunks)
    v[end] = exp(τ / σ)
    p = v ./ sum(v)
    return p, chunks
end

"""
    update_lags!(chunk::AbstractChunk, cur_time)

Compute lags for each use of a chunk.

# Arguments

- `chunk::AbstractChunks`: a chunk
- `cur_time`: current simulated time in seconds.

"""
function update_lags!(chunk::AbstractChunk, cur_time)
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
function update_chunk!(chunk::AbstractChunk, cur_time)
    update_recent!(chunk, cur_time)
    chunk.N += 1
    return nothing
end

"""
    add_chunk!(actr::AbstractACTR; slots...)

Adds new chunk to declarative memory or updates existing chunk with new use. The default time is
computed from `get_time`.

# Arguments 

- `actr::AbstractACTR`: an ACT-R model object

# Keywords

- `slots...`: optional keyword arguments corresponding to slot-value pairs, e.g. name=:Bob
"""
add_chunk!(actr::AbstractACTR; slots...) =
    add_chunk!(actr.declarative, get_time(actr); slots...)

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
function add_chunk!(memory::Declarative, cur_time = 0.0; bl::T = 0.0, slots...) where {T}
    chunk = get_chunks_exact(memory; slots...)
    if isempty(chunk)
        c = Chunk(;
            act = zero(T),
            bl,
            time_created = cur_time,
            recent = [cur_time],
            slots...
        )
        push!(memory.memory, c)
        return c
    else
        update_chunk!(chunk[1], cur_time)
        return chunk[1]
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
add_chunk!(actr::AbstractACTR, cur_time; slots...) =
    add_chunk!(actr.declarative, cur_time; slots...)

"""
    get_chunks_exact(memory::Vector{<:Chunk}; criteria...)

Returns all chunks that matches a set criteria and has the same number of slots.

# Arguments

- `memory::Vector{<:Chunk}`: vector of chunk objects

# Keywords

-`criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function get_chunks_exact(memory::Vector{<:AbstractChunk}; criteria...)
    c = filter(x -> match_exact(x, criteria), memory)
    return c
end

get_chunks_exact(d::Declarative; criteria...) = get_chunks_exact(d.memory; criteria...)

function match_exact(chunk::AbstractChunk, request)
    slots = chunk.slots
    length(slots) ≠ length(request) ? (return false) : nothing
    for (k, v) in request
        if !(k ∈ keys(slots)) || (slots[k] != v)
            return false
        end
    end
    return true
end

"""
    get_chunks(memory::Vector{<:AbstractChunk}; check_value=true, criteria...)

Returns all chunks that matches a set criteria.

# Arguments

- `memory::Vector{<:AbstractChunk}`: vector of chunk objects

# Keywords

 - `check_value=true`: check slot value 

-`criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function get_chunks(memory::Vector{<:AbstractChunk}; check_value = true, criteria...)
    c = filter(x -> _match(x, criteria; check_value), memory)
    return c
end

"""
    get_chunks(memory::Vector{<:AbstractChunk}, funs...; check_value=true, criteria...)

Returns all chunks that matches a set `criteria` which are evaluted according to the list of functions in `funs`.

# Arguments 

- `memory::Vector{<:AbstractChunk}`: vector of chunk objects
- `funs...`: a list of functions

# Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function get_chunks(
    memory::Vector{<:AbstractChunk},
    funs...;
    check_value = true,
    criteria...
)
    c = filter(x -> _match(x, funs, criteria; check_value), memory)
    return c
end

"""
    get_chunks(d::Declarative; check_value=true, criteria...)

Returns all chunks that matches a set criteria.

# Arguments

- `d::Declarative`: declarative memory object

# Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(d::Declarative; check_value = true, criteria...) =
    get_chunks(d.memory; check_value, criteria...)

"""
    get_chunks(actr::AbstractACTR; check_value=true, criteria...)

Returns all chunks that matches a set criteria

# Arguments

- `actr::AbstractACTR`: an ACTR Object

#Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(actr::AbstractACTR; check_value = true, criteria...) =
    get_chunks(actr.declarative.memory; check_value, criteria...)

"""
    get_chunks(d::Declarative, funs...; check_value=true, criteria...)

Returns all chunks that matches a set criteria using `funs...` as matching functions

# Arguments

- `d::Declarative`: declarative memory object
- `funs...`: a list of functions

# Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(d::Declarative, funs...; check_value = true, criteria...) =
    get_chunks(d.memory, funs...; check_value, criteria...)

"""
    get_chunks(actr::AbstractACTR, funs...; check_value=true, criteria...)

Returns all chunks that matches a set criteria using `funs...` as matching functions.

# Arguments

- `actr::AbstractACTR`: an ACT-R model object
- `funs...`: a list of functions

# Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
get_chunks(actr::AbstractACTR, funs...; check_value = true, criteria...) =
    get_chunks(actr.declarative.memory, funs...; check_value, criteria...)

"""
    first_chunk(memory::Vector{<:Chunk}; check_value=true, criteria...)

Returns the first chunk in memory that matches a set of criteria

# Arguments

- `memory::Vector{<:Chunk}`: a vector of chunks 

# Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function first_chunk(memory::Vector{<:AbstractChunk}; check_value = true, criteria...)
    chunk = Array{eltype(memory), 1}()
    for m in memory
        if _match(m, criteria; check_value)
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

- `d::Declarative`: a declarative memory object

# Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
first_chunk(d::Declarative; check_value = true, criteria...) =
    first_chunk(d.memory; check_value, criteria...)

"""
    first_chunk(actr::AbstractACTR; check_value=true, criteria...)

Returns the first chunk in memory that matches a set of criteria

# Arguments

- `actr::AbstractACTR`: an ACT-R model object

# Keywords

 - `check_value=true`: check slot value 

- `criteria...`: optional keyword arguments corresponding to critiria for matching chunk
"""
first_chunk(actr::AbstractACTR; check_value = true, criteria...) =
    first_chunk(actr.declarative.memory; check_value, criteria...)

"""
    _match(chunk::AbstractChunk, request; check_value=true)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

# Arguments

- `chunk::AbstractChunk`: chunk object
- `request`: a NamedTuple of slot value pairs

# Keywords

 - `check_value=true`: check slot value 
"""
function _match(chunk::AbstractChunk, request; check_value = true)
    slots = chunk.slots
    for (k, v) in request
        if !(k ∈ keys(slots))
            return false
        elseif check_value
            if (slots[k] != v)
                return false
            end
        end
    end
    return true
end

"""
    match(chunk::AbstractChunk, f, request)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

# Arguments

- `chunk::AbstractChunk`: a chunk object
- `f`: a list of functions such as `!=, ==`
- `request`: a NamedTuple of slot value pairs

# Keywords

 - `check_value=true`: check slot value 
"""
function _match(chunk::AbstractChunk, f, request; check_value = true)
    slots = chunk.slots
    i = 0
    for (k, v) in request
        i += 1
        if !(k ∈ keys(slots))
            return false
        elseif check_value
            if !(f[i](slots[k], v))
                return false
            end
        end
    end
    return true
end

"""
    match(chunk::AbstractChunk; request...)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

# Arguments

- `chunk::AbstractChunk`: a chunk object

# Keywords

- `request...`: optional keyword arguments corresponding to critiria for matching chunk
"""
function match(chunk::AbstractChunk; check_value = true, request...)
    return _match(chunk, request; check_value)
end
"""
    match(chunk::AbstractChunk, funs...; request...)

Returns a boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.

- `chunk::AbstractChunk`: chunk object
- `funs...`: a list of functions such as `!=, ==`
- `request...`: a NamedTuple of slot value pairs
"""
function match(chunk::AbstractChunk, funs...; check_value = true, request...)
    return _match(chunk, funs, request; check_value)
end

"""
    get_subset(actr::AbstractACTR; request...)

Returns a filtered subset of the retrieval request when partial matching is on.
By default, slot values for isa and retrieved must match exactly.

# Arguments

- `actr::AbstractACTR`: an ACTR object

# Keywords

- `request...`: an option set of keyword arguments corresponding to a retrieval request.
"""
function get_subset(actr::AbstractACTR; request...)
    return Iterators.filter(x -> any(s -> s == x[1], actr.declarative.filtered), request)
end

"""
    retrieval_request(actr::AbstractACTR; request...)

Returns chunks matching a retrieval request.

# Arguments

- `actr::AbstractACTR`: an ACT-R Object

# Keywords

- `request...`: optional keyword arguments corresponding to retrieval request e.g. dog = :fiddo
"""
function retrieval_request(actr::AbstractACTR; funs = (), request...)
    (; mmp,) = actr.parms
    !mmp ? (return get_chunks(actr, funs...; request...)) : nothing
    chunks = get_chunks(actr; check_value = false, request...)
    c = get_subset(actr; request...)
    return get_chunks(chunks; check_value = true, c...)
end

"""
    modify!(c; args...) 

Modifies fields of an object

# Arguments

- `c`: an object

# Keywords

- `args...`: optional keywords for field and values
"""
function modify!(c; args...)
    for (k, v) in args
        setfield!(c, k, v)
    end
    return nothing
end

"""
    modify!(c::NamedTuple; args...)

Modifies fields of NamedTuple

# Arguments

- `c`: a NamedTuple

# Keywords

- `args...`: optional keywords for field and values
"""
function modify!(c::NamedTuple; args...)
    for (k, v) in args
        c[k][1] = v
    end
    return nothing
end

"""
    retrieve(actr::AbstractACTR; request...)

Retrieves a chunk given a retrieval request. By default, current time is 
computed with `get_time`.

# Arguments 

- `actr::AbstractACTR`: an ACT-R object

# Keywords

- `request...`: optional keyword arguments representing a retrieval request, e.g. person=:bob

# Example 
```julia
using ACTRModels 
chunks = [Chunk(country=:Germany, capitol=:Berlin),
        Chunk(country=:Australia, capitol=:Canberra)]
declarative = Declarative(memory=chunks)
parms = (noise=true, s=0.20)
actr = ACTR(;declarative, parms...)
retrieve(actr; country=:Germany)
```
"""
function retrieve(actr::AbstractACTR; funs = (), request...)
    return retrieve(actr, get_time(actr); funs, request...)
end

"""
    retrieve(actr::AbstractACTR, cur_time; request...)

Retrieves a chunk given a retrieval request

# Arguments 

- `actr::AbstractACTR`: an ACT-R object
- `cur_time`: current simulated time in seconds

# Keywords

- `request...`: optional keyword arguments representing a retrieval request, e.g. person=:bob
"""
function retrieve(actr::AbstractACTR, cur_time; funs = (), request...)
    (; declarative, parms) = actr
    arr = Array{eltype(declarative.memory), 1}()
    _funs = isempty(funs) ? fill(==, length(request)) : funs
    chunks = retrieval_request(actr; funs = _funs, request...)
    # add noise to threshold even if result of request is empty
    actr.parms.noise ? add_noise!(actr) : (parms.τ′ = parms.τ)
    isempty(chunks) ? (return arr) : nothing
    compute_activation!(actr, chunks, cur_time; funs = _funs, request...)
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

- `chunks`: a vector of chunk objects
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
    compute_RT(actr, chunk)

Generates a reaction time for retrieving a chunk based
on the current activation levels of a chunk. If the vector is empty, time 
for a retrieval failure is returned.

# Arguments

- `actr`: ACTR object
- `chunk`: a vector that is empty or contains one chunk
"""
function compute_RT(actr::AbstractACTR, chunk)
    (; τ′, lf) = actr.parms
    if isempty(chunk)
        return lf * exp(-τ′)
    end
    return lf * exp(-chunk[1].act)
end

"""
    compute_RT(actr::AbstractACTR, chunk::AbstractChunk)

Generates a reaction time for retrieving a chunk based
on the current activation levels of a chunk.

# Arguments

- `actr::AbstractACTR`: ACTR object
- `chunk::AbstractChunk`: a chunk
"""
function compute_RT(actr::AbstractACTR, chunk::AbstractChunk)
    (; lf) = actr.parms
    return lf * exp(-chunk.act)
end

"""
    get_parm(actr::AbstractACTR, p)

Returns the value of a parameter

# Arguments

- `actr::AbstractACTR`: ACTR object
- ` p`: parameter name
"""
function get_parm(actr::AbstractACTR, p)
    misc = actr.parms.misc
    if p in keys(misc)
        return misc[p]
    end
    return getfield(actr.parms, p)
end

"""
    blend_chunks(actr::AbstractACTR, blended_slots; request...) 

Computes blended value over chunks given a retrieval request. By default, 
values are blended over the set of slots formed by the set difference between all 
slots of a chunk and the slots specified in the retrieval request. The default time used 
in activation calculations is taken from `get_time(actr`). Currently, blended 
is only supported for numeric slot-values. 

# Arguments

- `actr::AbstractACTR`: an `ACTR` model object 
- `blended_slots`: a set of slots over which slot-values are blended

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function blend_chunks(actr::AbstractACTR, blended_slots; request...)
    return blend_chunks(actr, blended_slots, get_time(actr); request...)
end

"""
    blend_chunks(actr, blended_slots, cur_time; request...)

Computes blended value over chunks given a retrieval request. Values are blended
over the slots specified in `blended_slots`. Currently, blended is only supported 
for numeric slot-values. 

# Arguments

- `actr`: an `ACTR` model object 
- `blended_slots`: a set of slots over which slot-values are blended
- `cur_time`: current simulated time

# Keywords

- `request...`: optional keywords for the retrieval request
"""
function blend_chunks(actr::AbstractACTR, blended_slots, cur_time; funs = (), request...)
    _funs = isempty(funs) ? fill(==, length(request)) : funs
    chunks = retrieval_request(actr; funs = _funs, request...)
    compute_activation!(actr, chunks, cur_time; funs = _funs, request...)
    probs = soft_max(actr, chunks)
    return blend_slots(actr, chunks, probs, blended_slots)
end

function blend_slots(
    actr::AbstractACTR,
    chunks::Vector{<:AbstractChunk},
    probs::Vector{<:Real},
    blended_slots
)
    return map(s -> blend_slots(actr, chunks, probs, s), blended_slots)
end

function blend_slots(
    actr::AbstractACTR,
    chunks::Vector{<:AbstractChunk},
    probs::Vector{<:Real},
    slot::Symbol
)
    values = map(c -> c.slots[slot], chunks)
    return blend_slots(actr, probs, values, slot)
end

"""
    blend_slots(actr::AbstractACTR, probs, values::AbstractArray{T}) where {T<:Number}

Computes an expected value over numerical values. 

# Arguments

- `actr::AbstractACTR`: an `ACTR` model object 
- `probs`: a vector of retrieval probabilities 
- `values::AbstractArray{T}`: values to be blended 
"""
function blend_slots(
    actr::AbstractACTR,
    probs::Vector{<:Real},
    values::AbstractArray{T},
    slot::Symbol
)::Float64 where {T <: Number}
    return probs' * values
end

"""
    blend_slots(actr::AbstractACTR, probs, values::AbstractArray{T}) where {T}

Computes an expected value over non-numerical values. 

# Arguments

- `actr::AbstractACTR`: an `ACTR` model object 
- `probs`: a vector of retrieval probabilities 
- `values::AbstractArray{T}`: values to be blended 
"""
function blend_slots(
    actr::AbstractACTR,
    probs::Vector{<:Real},
    values::AbstractArray{T},
    slot::Symbol
)::T where {T}
    n_vals = length(values)
    u_values = unique(values)
    n_unique = length(u_values)
    vals = zeros(n_unique)
    dissm_func = actr.parms.dissim_func
    for i ∈ 1:n_unique
        v = 0.0
        for j ∈ 1:n_vals
            v += probs[j] * dissm_func(slot, u_values[i], values[j], ==)^2
            #println("i $(u_values[i]) j $(values[j]) probs $(probs[j]) distance $(dissm_func(u_values[i], values[j])^2) v $v")
        end
        vals[i] = v
    end
    _, idx = findmin(vals)
    return u_values[idx]
end

function soft_max(actr, chunks)
    σ = actr.parms.tmp
    v = map(x -> exp(x.act / σ), chunks)
    return v ./ sum(v)
end

"""
    blended_activation(chunks)

Computes a blended activation value by exponentiating, summing and taking the 
log of activations across a set of chunks.

# Arguments

- `chunks`: a set of chunks over which slot-values are blended
"""
function blended_activation(chunks)
    exp_act = map(x -> exp(x.act), chunks)
    return log(sum(exp_act))
end

"""
    compute_RT(blended_act)

Computes retrieval time for a given blended activation value.

# Arguments

- `blended_act`: a blended activation value 
"""
compute_RT(blended_act) = exp(-blended_act)
