"""
Computes exact baselevel activation
* `d`: decay parameter
* `lags`: an array of time lags
"""
function baselevel(d, lags)
    act = 0.0
    for t in lags
        act += t^-d
    end
    return log(act)
end

"""
Computes baselevel activation according to the hybrid approximation
* `chunk`: chunk object
* `memory`: declarative memory object
"""
function baselevel!(chunk, memory)
    @unpack N,L,k,lags = chunk
    d = memory.parms.d
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

baselevel!(memory) = activation!.(memory.memory, memory)

"""
Computes the activation of a chunk or set of chunks
* `actr`: actr object
* `chunks`: a chunk or set of chunks. Default: all chunks in declarative memory
* `cur_time`: current time. Default 0.0 used when bll is false
* `request`: optional NamedTuple for retrieval request
"""
function compute_activation!(actr::AbstractACTR, chunks::Vector{<:Chunk}, cur_time::Float64=0.0; request...)
    memory = actr.declarative
    @unpack sa,noise = memory.parms
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

compute_activation!(actr, chunk::Chunk, cur_time=0.0; request...) = compute_activation!(actr, [chunk], cur_time; request...)

compute_activation!(actr::AbstractACTR, cur_time::Float64=0.0; request...) = compute_activation!(actr, actr.declarative.memory, cur_time; request...)

"""
Computes activation for a given chunk
* `actr`: ACT-R object
* `chunk`: chunk object
* `cur_time`: current time, default = 0
* `request`: optional keyword argument corresponding to retrieval request
"""
function activation!(actr, chunk::Chunk, cur_time=0.0; request...)
    memory = actr.declarative
    @unpack bll,mmp,sa,noise,blc,τ = memory.parms
    memory.parms.τ′ = τ
    reset_activation!(chunk)
    chunk.act_blc = blc + chunk.bl
    if bll
        update_lags!(chunk, cur_time)
        baselevel!(chunk, memory)
    end
    if mmp
        mismatch!(memory, chunk; request...)
    end
    if sa
        spreading_activation!(actr, chunk)
    end
    if noise
        add_noise!(memory, chunk)
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

function total_activation!(chunk)
    chunk.act = chunk.act_blc + chunk.act_bll - chunk.act_pm +
        chunk.act_sa + chunk.act_noise
    return nothing
end

function add_noise!(memory, chunk)
    @unpack τ,s = memory.parms
    σ = s * pi / sqrt(3)
    chunk.act_noise = rand(Normal(0, σ))
    memory.parms.τ′ = rand(Normal(τ, σ))
    return nothing
end

function mismatch!(memory, chunk; request...)
    p = memory.parms.mmpFun(memory, chunk; request...)
    chunk.act_pm = p
    return nothing
end

"""
Set noise true or false.
* `actr`: ACTR object
* `v`: boolean value
"""
set_noise!(actr::AbstractACTR, b) = set_noise!(actr.declarative, b)

function set_noise!(memory::Declarative, b)
    memory.parms.noise = b
end

spreading_activation!(actr, chunk) = spreading_activation!(actr.declarative, actr.imaginal, chunk)

"""
Computes the spreading activation for a given chunk
* `actr`: actr object or declarative memory object
* `imaginal`: imaginal object
* `chunk`: the chunk for which spreading activation is computed
"""
function spreading_activation!(memory, imaginal, chunk)
    w = compute_weights(imaginal)
    r = 0.0; sa = 0.0; γ = memory.parms.γ
    slots = imaginal.chunk.slots
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
    slots = imaginal.chunk.slots
    denoms = fill(0, length(slots))
    for (i,v) in enumerate(slots)
        denoms[i] = compute_denom(declarative, v)
    end
    imaginal.denoms = denoms
    return nothing
end

function compute_weights(mod)
    return mod.ω / length(mod.chunk.slots)
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
Adds a new timestamp to chunk and removes oldest timestamp if
length equals k.
* `chunk`: memory chunk object
* `cur_time`: current time in seconds
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
Computes the retrieval probability of a single chunk or the marginal probability of retrieving any chunk from a set of chunks.
* `actr`: an actr object
* `chunk`: a chunk or array of chunks
* `cur_time`: current time. Default 0.0 to be used when bll is false
* `request`: optional NamedTuple for retrieval request
"""
function retrieval_prob(actr::AbstractACTR, target::Array{<:Chunk,1}, cur_time=0.0; request...)
    @unpack τ,s,noise = actr.declarative.parms
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

function retrieval_prob(actr::AbstractACTR, chunk::Chunk, cur_time=0.0; request...)
    @unpack τ,s,noise = actr.declarative.parms
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
Computes the retrieval probability for each chunk matching the retrieval request.
* `actr`: an actr object
* `cur_time`: current time. Default 0.0 to be used when bll is false
* `request`: optional NamedTuple for retrieval request
"""
function retrieval_probs(actr::AbstractACTR, cur_time=0.0; request...)
    @unpack τ,s,γ,noise = actr.declarative.parms
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

function update_lags!(chunk::Chunk, cur_time)
    chunk.L = cur_time - chunk.time_created
    chunk.lags = cur_time .- chunk.recent
    return nothing
end

update_lags!(actr::AbstractACTR, cur_time) = update_lags!(actr.declarative, cur_time)

update_lags!(memory::Declarative, cur_time) = update_lags!.(memory.memory, cur_time)

function update_chunk!(chunk, cur_time)
    update_recent!(chunk, cur_time)
    chunk.N += 1
    return nothing
end

"""
Adds new chunk to declarative memory or updates existing chunk with new use
* `memory`: declarative memory object
* `cur_time`: current time, default = 0.0
* `slots`: optional keyword arguments corresponding to slot-value pairs, e.g. name=:Bob
"""
function add_chunk!(memory::Declarative, cur_time=0.0; act=0.0, slots...)
    chunk = get_chunk(memory; slots...)
    if isempty(chunk)
        c = Chunk(;act=act, time_created=cur_time, recent=[cur_time], slots...)
        push!(memory.memory, c)
    else
        update_chunk!(chunk[1], cur_time)
    end
    return nothing
end

add_chunk!(actr::ACTR, cur_time=0.0; request...) = add_chunk!(actr.declarative, cur_time; request...)

"""
Returns all chunks that matches a set criteria
* `memory`: vector of chunk objects
* `args`: optional keyword arguments corresponding to critiria for matching chunk
"""
function get_chunk(memory::Vector{<:Chunk}; args...)
    c = filter(x -> match(x, args), memory)
    return c
end

function get_chunk(memory::Vector{<:Chunk}, funs...; args...)
    c = filter(x -> match(x, funs...; args...), memory)
    return c
end

get_chunk(d::Declarative; args...) = get_chunk(d.memory; args...)

get_chunk(a::AbstractACTR; args...) = get_chunk(a.declarative.memory; args...)

get_chunk(d::Declarative, funs...; args...) = get_chunk(d.memory, funs...; args...)

get_chunk(a::AbstractACTR, funs...; args...) = get_chunk(a.declarative.memory, funs...; args...)

"""
Returns the first chunk in memory that matches a set of criteria
* `memory`: delcarative memory object
* `args`: optional keyword arguments corresponding to critiria for matching chunk
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

first_chunk(d::Declarative; args...) = first_chunk(d.memory; args...)

first_chunk(a::AbstractACTR; args...) = first_chunk(a.declarative.memory; args...)

"""
Returns boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.
* `chunk`: chunk object
* `request`: a NamedTuple of slot value pairs
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

match(chunk::Chunk; request...) = match(chunk, request)

match(chunk::Chunk, funs...; request...) = match(chunk, funs, request)

"""
Returns a filtered subset of the retrieval request when partial matching is on.
By default, slot values for isa and retrieved must match exactly.
"""
function get_subset(declarative; request...)
    return Iterators.filter(x -> any(s->s == x[1], declarative.filtered),
    request)
end

"""
Returns chunks matching a retrieval request.
* `memory`: declarative memory object
* `request`: optional keyword arguments corresponding to retrieval request e.g. dog = :fiddo
"""
function retrieval_request(memory::Declarative; request...)
    @unpack mmp = memory.parms
    if !mmp
        return get_chunk(memory; request...)
    end
    c = get_subset(memory; request...)
    return get_chunk(memory; c...)
end

retrieval_request(a::AbstractACTR; request...) =  retrieval_request(a.declarative; request...)

"""
Modfy fields of an object
* `c`: an object
* `args`: optional keywords for field and values
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
Retrieves a chunk given a retrieval request
* `actr`: an ACT-R object
* `cur_time`: current time, default 0.0 (use when base level learning is false)
* `request`: optional keyword arguments representing a retrieval request, e.g. person=:bob
"""
function retrieve(actr::AbstractACTR, cur_time=0.0; request...)
    memory = actr.declarative
    arr = Array{eltype(memory.memory),1}()
    chunks = retrieval_request(actr; request...)
    isempty(chunks) ? (return arr) : nothing
    compute_activation!(actr, chunks, cur_time; request...)
    τ′ = memory.parms.τ′
    best = get_max_active(chunks)
    if best[1].act >= τ′
        return best
    end
    return arr
end

"""
Returns the chunk with maximum activation
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
Samples a reaction time for retrieving a chunk
* `memory`: declarative memory object
* `chunk`: target chunk for reaction time
"""
function compute_RT(memory::Declarative, chunk)
    @unpack τ′,lf = memory.parms
    if isempty(chunk)
        return lf * exp(-τ′)
    end
    return lf * exp(-chunk[1].act)
end

function compute_RT(memory::Declarative, chunk::Chunk)
    @unpack lf = memory.parms
    return lf * exp(-chunk.act)
end

compute_RT(actr::ACTR, chunk) = compute_RT(actr.declarative, chunk)
compute_RT(actr::ACTR, chunk::Chunk) = compute_RT(actr.declarative, chunk)


"""
Returns a miscelleneous parameter
* `actr`: ACTR object
* ` p`: parameter name
"""
function get_parm(actr, p)
    misc = actr.declarative.parms.misc
    if p in keys(misc)
        return misc[p]
    end
    return getfield(actr.declarative.parms, p)
end