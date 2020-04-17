"""
Computes exact baselevel activation
* `d`: decay parameter
* `lags`: an array of time lags
"""
function baseLevel(d, lags)
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
function baseLevel!(chunk, memory)
    @unpack N,L,k,lags=chunk
    d = memory.parms.d
    exact = baseLevel(d, lags)
    approx = 0.0
    if N > k
        tk = lags[k]
        x1 = (N-k)*(L^(1-d)-tk^(1-d))
        x2 = (1-d)*(L-tk)
        approx = x1/x2
    end
    chunk.act_bll = log(exp(exact) + approx)
    return nothing
end

baseLevel!(memory) = activation!.(memory.memory, memory)

"""
Computes the activation of a chunk or set of chunks
* `actr`: actr object
* `chunks`: a chunk or set of chunks. Default: all chunks in declarative memory
* `curTime`: current time. Default 0.0 used when bll is false
* `request`: optional NamedTuple for retrieval request
"""
function computeActivation!(actr::ACTR, chunks::Vector{<:Chunk}, curTime::Float64=0.0; request...)
    memory = actr.declarative
    @unpack sa,noise=memory.parms
    if sa
        #Cache denoms in spreading activation for effeciency
        spreadingActivation!(actr)
    end
    #compute activation for each chunk
    for chunk in chunks
        activation!(actr, chunk, curTime; request...)
    end
    return nothing
end

computeActivation!(actr, chunk::Chunk, curTime=0.0; request...) = computeActivation!(actr, [chunk], curTime; request...)

computeActivation!(actr::ACTR, curTime::Float64=0.0; request...) = computeActivation!(actr, actr.declarative.memory, curTime; request...)

"""
Computes activation for a given chunk
* `actr`: ACT-R object
* `chunk`: chunk object
* `curTime`: current time, default = 0
* `request`: optional keyword argument corresponding to retrieval request
"""
function activation!(actr, chunk::Chunk, curTime=0.0; request...)
    memory = actr.declarative
    @unpack bll,mmp,sa,noise,blc,τ=memory.parms
    memory.parms.τ′ = τ
    chunk.act_blc = blc + chunk.bl
    if bll
        updateLags!(chunk, curTime)
        baseLevel!(chunk, memory)
    end
    if mmp
        mismatch!(memory, chunk; request...)
    end
    if sa
        spreadingActivation!(actr, chunk)
    end
    if noise
        addNoise!(memory, chunk)
    end
    total_activation!(chunk)
    return nothing
end

function total_activation!(chunk)
    chunk.act = chunk.act_blc + chunk.act_bll - chunk.act_pm +
        chunk.act_sa + chunk.act_noise
    return nothing
end

function addNoise!(memory, chunk)
    @unpack τ,s = memory.parms
    σ = s*pi/sqrt(3)
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
setNoise!(actr::ACTR, b) = setNoise!(actr.declarative, b)

function setNoise!(memory::Declarative, b)
    memory.parms.noise = b
end

spreadingActivation!(actr, chunk) = spreadingActivation!(actr.declarative, actr.imaginal, chunk)

"""
Computes the spreading activation for a given chunk
* `actr`: actr object or declarative memory object
* `imaginal`: imaginal object
* `chunk`: the chunk for which spreading activation is computed
"""
function spreadingActivation!(memory, imaginal, chunk)
    w = computeWeights(imaginal)
    r=0.0; sa=0.0; γ=memory.parms.γ
    slots = imaginal.chunk.slots
    denoms = imaginal.denoms
    for (v,d) in zip(slots, denoms)
        num = countValues(chunk, v)
        fan = num/(d+1)
        fan == 0 ? r=0.0 : r=γ+log(fan)
        sa += w*r
    end
    chunk.act_sa = sa#max(0.0,sa)#causes errors in gradient
    return nothing
end

#Caches the denominator of spreading activation
function spreadingActivation!(actr)
    @unpack imaginal,declarative=actr
    slots = imaginal.chunk.slots
    denoms = fill(0,length(slots))
    for (i,v) in enumerate(slots)
        denoms[i] = computeDenom(declarative, v)
    end
    imaginal.denoms = denoms
    return nothing
end

function computeWeights(mod)
    return mod.ω/length(mod.chunk.slots)
end

function computeDenom(memory, value)
    denom = 0
    for c in memory.memory
        denom += countValues(c, value)
    end
    return denom
end

function countValues(chunk, value)
    return count(x->x==value, values(chunk.slots))
end

"""
Adds a new timestamp to chunk and removes oldest timestamp if
length equals k.
* `chunk`: memory chunk object
* `curTime`: current time in seconds
"""
function updateRecent!(chunk, curTime)
    k = chunk.k; recent = chunk.recent
    if length(recent) == k
        pop!(recent)
    end
    pushfirst!(recent, curTime)
    return nothing
end

"""
Computes the retrieval probability of a single chunk or the marginal probability of retrieving any chunk from a set of chunks.
* `actr`: an actr object
* `chunk`: a chunk or array of chunks
* `curTime`: current time. Default 0.0 to be used when bll is false
* `request`: optional NamedTuple for retrieval request
"""
function retrievalProb(actr::ACTR, target::Array{<:Chunk,1}, curTime=0.0; request...)
    @unpack τ,s,noise = actr.declarative.parms
    σ′ = s*sqrt(2)
    chunks = retrievalRequest(actr; request...)
    filter!(x->(x ∈ chunks), target)
    isempty(target) ? (return (0.0,1.0)) : nothing
    setNoise!(actr, false)
    computeActivation!(actr, chunks, curTime; request...)
    denom = fill(target[1].act, length(chunks)+1)
    map!(x->exp(x.act/σ′), denom, chunks)
    denom[end]=exp(τ/σ′)
    num = map(x->exp(x.act/σ′), target)
    prob = sum(num)/sum(denom)
    fail = denom[end]/sum(denom)
    setNoise!(actr, noise)
    return prob,fail
end

function retrievalProb(actr::ACTR, chunk::Chunk, curTime=0.0; request...)
    @unpack τ,s,noise = actr.declarative.parms
    σ′ = s*sqrt(2)
    chunks = retrievalRequest(actr; request...)
    !(chunk ∈ chunks) ? (return (0.0,1.0)) : nothing
    setNoise!(actr, false)
    computeActivation!(actr, chunks, curTime; request...)
    v = fill(chunk.act, length(chunks)+1)
    map!(x->exp(x.act/σ′), v, chunks)
    v[end]=exp(τ/σ′)
    prob = exp(chunk.act/σ′)/sum(v)
    fail = v[end]/sum(v)
    setNoise!(actr, noise)
    return prob,fail
end

"""
Computes the retrieval probability for each chunk matching the retrieval request.
* `actr`: an actr object
* `curTime`: current time. Default 0.0 to be used when bll is false
* `request`: optional NamedTuple for retrieval request
"""
function retrievalProbs(actr::ACTR, curTime=0.0; request...)
    @unpack τ,s,γ,noise = actr.declarative.parms
    σ′ = s*sqrt(2)
    setNoise!(actr, false)
    chunks = retrievalRequest(actr; request...)
    isempty(chunks) ? (return ([0.0],chunks)) : nothing
    computeActivation!(actr, chunks, curTime; request...)
    v = Array{typeof(chunks[1].act), 1}(undef, length(chunks)+1)
    map!(x->exp(x.act/σ′), v, chunks)
    v[end] = exp(τ/σ′)
    p = v./sum(v)
    setNoise!(actr, noise)
    return p,chunks
end

function updateLags!(chunk::Chunk, curTime)
    chunk.L = curTime - chunk.created
    chunk.lags = curTime .- chunk.recent
    return nothing
end

updateLags!(actr::ACTR, curTime) = updateLags!(actr.declarative, curTime)

updateLags!(memory::Declarative, curTime) = updateLags!.(memory.memory, curTime)

function updateChunk!(chunk, curTime)
    updateRecent!(chunk, curTime)
    chunk.N += 1
    return nothing
end

"""
Adds new chunk to declarative memory or updates existing chunk with new use
* `memory`: declarative memory object
* `curTime`: current time, default = 0.0
* `slots`: optional keyword arguments corresponding to slot-value pairs, e.g. name=:Bob
"""
function addChunk!(memory::Declarative, curTime=0.0; act=0.0, slots...)
    chunk = getChunk(memory; slots...)
    if isempty(chunk)
        c = Chunk(;act=act, created=curTime, recent=[curTime], slots...)
        push!(memory.memory, c)
    else
        updateChunk!(chunk[1], curTime)
    end
    return nothing
end

addChunk!(actr::ACTR, curTime=0.0; request...) = addChunk!(actr.declarative, curTime; request...)

"""
Returns all chunks that matches a set criteria
* `memory`: vector of chunk objects
* `args`: optional keyword arguments corresponding to critiria for matching chunk
"""
function getChunk(memory::Vector{<:Chunk}; args...)
    c = filter(x->Match(x, args), memory)
    return c
end

function getChunk(memory::Vector{<:Chunk}, funs...; args...)
    c = filter(x->Match(x, funs...; args...), memory)
    return c
end

getChunk(d::Declarative; args...) = getChunk(d.memory; args...)

getChunk(a::ACTR; args...) = getChunk(a.declarative.memory; args...)

getChunk(d::Declarative, funs...; args...) = getChunk(d.memory, funs...; args...)

getChunk(a::ACTR, funs...; args...) = getChunk(a.declarative.memory, funs...; args...)

"""
Returns the first chunk in memory that matches a set of criteria
* `memory`: delcarative memory object
* `args`: optional keyword arguments corresponding to critiria for matching chunk
"""
function firstChunk(memory::Vector{<:Chunk}; args...)
    chunk = Array{eltype(memory), 1}()
    for m in memory
        if Match(m, args)
            push!(chunk, m)
            return chunk
        end
    end
    return chunk
end

firstChunk(d::Declarative; args...) = firstChunk(d.memory; args...)

firstChunk(a::ACTR; args...) = firstChunk(a.declarative.memory; args...)

"""
Returns boolean indicating whether a request matches a chunk.
False is returned if the slot does not exist in the chunk or the value
of the slot does not match the request value.
* `chunk`: chunk object
* `request`: a NamedTuple of slot value pairs
"""
function Match(chunk, request)
    slots = chunk.slots
    for (k,v) in request
        if !(k ∈ keys(slots)) || (slots[k] != v)
            return false
        end
     end
     return true
end

function Match(chunk, f, request)
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

Match(chunk; request...) = Match(chunk, request)

Match(chunk, funs...; request...) = Match(chunk, funs, request)

function getSubSet(;request...)
    return Iterators.filter(x->(x[1]==:isa) || (x[1]==:retrieved),
    request)
end

"""
Returns chunks matching a retrieval request.
* `memory`: declarative memory object
* `request`: optional keyword arguments corresponding to retrieval request e.g. dog= :fiddo
"""
function retrievalRequest(memory::Declarative; request...)
    @unpack mmp=memory.parms
    if !mmp
        return getChunk(memory; request...)
    end
    c = getSubSet(;request...)
    return getChunk(memory; c...)
end

retrievalRequest(a::ACTR; request...) =  retrievalRequest(a.declarative; request...)

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

"""
Retrieves a chunk given a retrieval request
* `actr`: an ACT-R object
* `curTime`: current time, default 0.0 (use when base level learning is false)
* `request`: optional keyword arguments representing a retrieval request, e.g. person=:bob
"""
function retrieve(actr::ACTR, curTime=0.0; request...)
    memory = actr.declarative
    arr = Array{eltype(memory.memory), 1}()
    chunks = retrievalRequest(actr; request...)
    isempty(chunks) ? (return arr) : nothing
    computeActivation!(actr, chunks, curTime; request...)
    τ′= memory.parms.τ′
    best = getMaxActive(chunks)
    if best[1].act >= τ′
        return best
    end
    return arr
end

"""
Returns the chunk with maximum activation
* `chunks`: a vector of chunk objects
"""
function getMaxActive(chunks)
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
function computeRT(memory::Declarative, chunk)
    @unpack τ′,lf = memory.parms
    if isempty(chunk)
         return lf*exp(-τ′)
    end
    return lf*exp(-chunk[1].act)
end

computeRT(actr::ACTR, chunk) = computeRT(actr.declarative, chunk)

"""
Returns a miscelleneous parameter
* `actr`: ACTR object
* ` p`: parameter name
"""
get_parm(actr, p) = actr.declarative.parms.misc[p]
