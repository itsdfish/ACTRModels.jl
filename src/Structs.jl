abstract type AbstractBufferState end

"""
    BufferState(;busy, error, empty)

An object representing the state of the buffer.

# Fields

- `busy=false`: busy if true
- `error=false`: error if true
- `empty=true`: empty if true
"""
mutable struct BufferState <: AbstractBufferState
    busy::Bool
    error::Bool
    empty::Bool
end

BufferState(; busy = false, error = false, empty = true) = BufferState(busy, error, empty)

abstract type AbstractParms end

"""
    Parms(; kwargs...) -> Parms 

ACT-R parameters with default values. Default values are overwritten with keyword arguments.

# Fields

- `d=0.5`: activation decay
- `τ=0.0`: retrieval threshold
- `s=0.2`: logistic scalar for activation noise.
- `γ=1.6`: maximum associative strength
- `δ=0.0`: mismatch penalty
- `ω=1.0`: weight for source of spreading activation
- `blc=0.0`: base level constant
- `ter=0.0`: a constant for encoding and responding time
- `dissim_func`: computes dissimilarity between two slot values. Output ranges from 0 (maximally similar) to 1 (maximially dissimilar)
- `sa_fun`: a function for spreading activation which requires arguments for actr and chunk
- `util_mmp_fun`: utility mismatch penalty function applied to each condition
- `lf=1.0:` latency factor parameter
- `u0=0.0`: initial utility value
- `σu=.2`: standard deviation of utility noise 
- `δu=1.0`: mismatch penalty parameter for utility
- `τu0 = -100`: initial value of utility threshold 
- `τu = τu0`: utility threshold 
- `u0Δ = 1.0`: utility decrement
- `τuΔ = 1.0`: utility threshold decrement
- `utility_decrement=1.0`: the utility decrement scalar. After each microlapse, `utility_decrement` is multiplied by u0Δ
- `threshold_decrement=1.0`: the threshold decrement scalar. After each microlapse, `threshold_decrement` is multiplied by τuΔ
- `bll=false`: base level learning on
- `mmp=false`: mismatch penalty on
- `sa=false`: spreading activatin on
- `noise=false`: noise on
- `mmp_utility=false`: mismatch penalty for procedural memory
- `utility_noise=false`: utility noise for procedural memory
- `tmp=s * √(2)`: temperature for blending
- `misc`: `NamedTuple` of extra parameters
- `filtered:` a list of slots that must absolutely match with mismatch penalty. `isa` and `retrieval` are included
    by default
"""
@concrete mutable struct Parms{T <: Real} <: AbstractParms
    d::T
    τ::T
    s::T
    γ::T
    δ::T
    ω::T
    blc::T
    ter::T
    dissim_func
    sa_fun
    util_mmp_fun
    lf::T
    τ′::T
    u0::T
    σu::T
    δu::T
    τu0::T
    τu::T
    u0Δ::T
    τuΔ::T
    utility_decrement::T
    threshold_decrement::T
    bll::Bool
    mmp::Bool
    sa::Bool
    noise::Bool
    mmp_utility::Bool
    utility_noise::Bool
    tmp::T
    misc
end

function Parms(;
    d = 0.5,
    τ = 0.0,
    s = 0.3,
    γ = 0.0,
    δ = 0.0,
    ω = 1.0,
    blc = 0.0,
    ter = 0.0,
    dissim_func = default_dissim_func,
    sa_fun = spreading_activation!,
    util_mmp_fun = utility_match,
    lf = 1.0,
    τ′ = τ,
    u0 = 0.0,
    σu = 0.2,
    δu = 1.0,
    τu0 = -100.0,
    τu = τu0,
    u0Δ = 1.0,
    τuΔ = 1.0,
    utility_decrement = 1.0,
    threshold_decrement = 1.0,
    bll = false,
    mmp = false,
    sa = false,
    noise = false,
    mmp_utility = false,
    utility_noise = false,
    tmp = s * sqrt(2),
    kwargs...
)
    d,
    τ,
    s,
    γ,
    δ,
    ω,
    blc,
    ter,
    lf,
    τ′,
    u0,
    σu,
    δu,
    τu0,
    τu,
    u0Δ,
    τuΔ,
    utility_decrement,
    threshold_decrement,
    tmp = promote(
        d,
        τ,
        s,
        γ,
        δ,
        ω,
        blc,
        ter,
        lf,
        τ′,
        u0,
        σu,
        δu,
        τu0,
        τu,
        u0Δ,
        τuΔ,
        utility_decrement,
        threshold_decrement,
        tmp
    )

    return Parms(
        d,
        τ,
        s,
        γ,
        δ,
        ω,
        blc,
        ter,
        dissim_func,
        sa_fun,
        util_mmp_fun,
        lf,
        τ′,
        u0,
        σu,
        δu,
        τu0,
        τu,
        u0Δ,
        τuΔ,
        utility_decrement,
        threshold_decrement,
        bll,
        mmp,
        sa,
        noise,
        mmp_utility,
        utility_noise,
        tmp,
        NamedTuple(kwargs)
    )
end

function Base.show(io::IO, ::MIME"text/plain", parms::Parms)
    values = [getfield(parms, f) for f in fieldnames(Parms)]
    values = map(x -> typeof(x) == Bool ? string(x) : x, values)
    return pretty_table(
        io,
        values;
        title = "Model Parameters",
        row_label_column_title = "Parameter",
        compact_printing = false,
        header = ["Value"],
        row_label_alignment = :l,
        row_labels = [fieldnames(Parms)...],
        formatters = ft_printf("%5.2f"),
        alignment = :l
    )
end

abstract type AbstractChunk end

"""
    Chunk

An object representing a declarative memory chunk.

# Fields

- `N=1.0`: number of uses
- `L=1.0`: lifetime of chunk
- `time_created=0.0`: time at which the chunk was created
- `k=1`: number of chunks in recent set (k=1 is sufficient)
- `act=0.0`: total activation
- `act_blc=0.0`: base level constant component of activation
- `act_bll=0.0`: base level learning component of activation
- `act_pm=0.0`: partial matching component of activation
- `act_sa=0.0`: spreading activation component of activation
- `act_noise=0.0`: noise component of activation
- `slots`: chunk slot-value pairs
- `reps=0`: number of identical chunks. This can be used in simple cases to speed up the code.
- `recent=[0.0]`: time stamps for k recent retrievals
- `lags=Float64[]`: lags for recent retrievals (L - recent)
- `bl=0.0`: baselevel constant added to chunks activation
"""
mutable struct Chunk{T1, T2} <: AbstractChunk
    N::Int
    L::Float64
    time_created::Float64
    k::Int
    act_mean::T2
    act::T2
    act_blc::T2
    act_bll::T2
    act_pm::T2
    act_sa::T2
    act_noise::T2
    slots::T1
    reps::Int64
    recent::Array{Float64, 1}
    lags::Array{Float64, 1}
    bl::T2
end

"""
    Chunk(;
        N = 1,
        L = 1.0,
        time_created = 0.0,
        k = 1, 
        act = 0.0, 
        recent = [0.0],
        reps = 0, 
        lags = Float64[], 
        bl = zero(typeof(act)),
        slots...)

An object representing a declarative memory chunk.

# Keywords

- `N=1.0`: number of uses
- `L=1.0`: lifetime of chunk
- `time_created=0.0`: time at which the chunk was created
- `k=1`: number of chunks in recent set (k=1 is sufficient)
- `act=0.0`: total activation
- `act_blc=0.0`: base level constant component of activation
- `act_bll=0.0`: base level learning component of activation
- `act_pm=0.0`: partial matching component of activation
- `act_sa=0.0`: spreading activation component of activation
- `act_noise=0.0`: noise component of activation
- `slots`: chunk slot-value pairs
- `reps=0`: number of identical chunks. This can be used in simple cases to speed up the code.
- `recent=[0.0]`: time stamps for k recent retrievals
- `lags=Float64[]`: lags for recent retrievals (L - recent)
- `bl=0.0`: baselevel constant added to chunks activation

# Example 

```@example
using ACTRModels

chunk = Chunk(; name = :Bonkers, animal = :rat)
```
"""
function Chunk(;
    N = 1,
    L = 1.0,
    time_created = 0.0,
    k = 1,
    act = 0.0,
    recent = [0.0],
    reps = 0,
    lags = Float64[],
    bl = zero(typeof(act)),
    slots...
)
    T = typeof(act)
    act_mean = zero(T)
    act_pm = zero(T)
    act_blc = zero(T)
    act_bll = zero(T)
    act_noise = zero(T)
    act_sa = zero(T)
    return Chunk(
        N,
        L,
        time_created,
        k,
        act_mean,
        act,
        act_blc,
        act_bll,
        act_pm,
        act_sa,
        act_noise,
        NamedTuple(slots),
        reps,
        recent,
        lags,
        bl
    )
end

"""
    Chunk(dynamic::Bool; 
        N = 1,
        L = 1.0,
        time_created = 0.0,
        k = 1, 
        act = 0.0, 
        recent = [0.0],
        reps = 0, 
        lags = Float64[], 
        bl = zero(typeof(act)),
        slots...)

A declarative memory chunk with dynamic slot-value pairs.

# Fields

- `dynamic::Bool`: slot-value pairs are mutable if true
- `N=1.0`: number of uses
- `L=1.0`: lifetime of chunk
- `time_created=0.0`: time at which the chunk was created
- `k=1`: number of chunks in recent set (k=1 is sufficient)
- `act_mean`: mean activation computed as `act` - `act_noise`
- `act=0.0`: total activation computed as `act_mean` + `act_noise`
- `act_blc=0.0`: base level constant component of activation
- `act_bll=0.0`: base level learning component of activation
- `act_pm=0.0`: partial matching component of activation
- `act_sa=0.0`: spreading activation component of activation
- `act_noise=0.0`: noise component of activation
- `slots`: chunk slot-value pairs
- `reps=0`: number of identical chunks. This can be used in simple cases to speed up the code.
- `recent=[0.0]`: time stamps for k recent retrievals
- `lags=Float64[]`: lags for recent retrievals (L - recent)
- `bl=0.0`: baselevel constant added to chunks activation
"""
function Chunk(
    dynamic::Bool;
    N = 1,
    L = 1.0,
    time_created = 0.0,
    k = 1,
    act = 0.0,
    recent = [0.0],
    reps = 0,
    lags = Float64[],
    bl = zero(typeof(act)),
    slots...
)
    T = typeof(act)
    act_mean = zero(T)
    act_pm = zero(T)
    act_blc = zero(T)
    act_bll = zero(T)
    act_noise = zero(T)
    act_sa = zero(T)
    slots = Dict(k => v for (k, v) in pairs(slots))
    return Chunk(
        N,
        L,
        time_created,
        k,
        act_mean,
        act,
        act_blc,
        act_bll,
        act_pm,
        act_sa,
        act_noise,
        slots,
        reps,
        recent,
        lags,
        bl
    )
end

Broadcast.broadcastable(x::AbstractChunk) = Ref(x)

const chunk_fields = (
    :slots,
    :N,
    :L,
    :time_created,
    :recent,
    :act_mean,
    :act,
    :act_blc,
    :bl,
    :act_bll,
    :act_pm,
    :act_noise
)

function chunk_values(chunk)
    values = [getfield(chunk, f) for f in chunk_fields]
    return map(x -> typeof(x) == Bool ? string(x) : x, values)
end

function Base.show(io::IO, ::MIME"text/plain", chunk::AbstractChunk)
    values = chunk_values(chunk)
    return pretty_table(
        io,
        values;
        title = "Chunk",
        row_label_column_title = "Property",
        compact_printing = false,
        header = ["Value"],
        row_label_alignment = :l,
        row_labels = [chunk_fields...],
        formatters = ft_printf("%5.2f"),
        alignment = :l
    )
end

function Base.show(io::IO, ::MIME"text/plain", chunks::Vector{<:Chunk})
    table = [chunk_values(chunk) for chunk in chunks]
    table = hcat(table...)
    table = permutedims(table)
    table = isempty(chunks) ? fill(Missing, 1, length(chunk_fields)) : table

    return pretty_table(
        io,
        table;
        title = "Chunks",
        # row_name_column_title="Parameter",
        compact_printing = false,
        header = [chunk_fields...],
        row_label_alignment = :l,
        formatters = ft_printf("%5.2f"),
        alignment = :l
    )
end

abstract type Mod end

"""
    Declarative(;memory=, filtered=(:isa,:retrieved))

Declarative memory module

# Fields 

- `memory=Chunk[]`: array of chunks
- `filtered`: slots that must match exactly even when partial matching is on. By default, 
    `filtered=(:isa,:retrieved)`
- `buffer`: an array containing one chunk
- `state`: buffer state
"""
mutable struct Declarative{T1, T2, B} <: Mod
    memory::Array{T1, 1}
    filtered::T2
    buffer::Array{T1, 1}
    state::B
end

function Declarative(; memory = Chunk[], filtered = (:isa, :retrieved))
    state = BufferState()
    return Declarative(memory, filtered, typeof(memory)(undef, 1), state)
end

"""
    default_dissim_func(s, v1, v2)

A default dissimilarity function which returns 1 for a mismatch and 0 otherwise.

# Arguments 

- `s`: the slot
- `v1`: slot value 1
- `v2`: slot value 2
"""
default_dissim_func(s, v1, v2) = v1 ≠ v2 ? 1.0 : 0.0

Broadcast.broadcastable(x::Declarative) = Ref(x)

"""
    Imaginal(;buffer=Chunk[], ω=1.0, denoms=Int64[]) 

Imaginal Module.

# Fields

- `buffer`: an array holding up to one chunk
- `state`: buffer state
- `ω=1.0`: fan weight. Default is 1.
- `denoms=Int64[]`: cached value for the denominator of the fan calculation
"""
mutable struct Imaginal{T1, T2, B} <: Mod
    buffer::Array{T1, 1}
    state::B
    ω::T2
    denoms::Vector{Int64}
end

function Imaginal(; buffer = Chunk[], ω = 1.0, denoms = Int64[])
    state = BufferState()
    return Imaginal(buffer, state, ω, denoms)
end

Imaginal(chunk::AbstractChunk, state, ω, denoms) = Imaginal([chunk], state, ω, denoms)
Imaginal(T::DataType, state, ω, denoms) = Imaginal(T(undef, 1), state, ω, denoms)

"""
    Visual(;chunk=Chunk()) 

Visual Module.

# Fields 

- `buffer`: an array holding up to one chunk
- `state`: buffer state
- `focus`: coordinates of visual attention
"""
mutable struct Visual{T1, B} <: Mod
    buffer::Array{T1, 1}
    state::B
    focus::Vector{Float64}
end

Visual(; buffer = Chunk[]) = Visual(buffer, BufferState(), fill(0.0, 2))
Visual(chunk::AbstractChunk, state, focus) = Visual([chunk], state, focus)
Visual(T::DataType, state, focus) = Visual(T(undef, 1), state, focus)

abstract type AbstractVisualObject end
"""
    VisualObject(;x=300.0, y=300.0, color=:black, text="", shape=:_, width=30.0, height=30.0) 

A visible object in a task. 

# Fields 

- `x`: x coordinate of visual object. Default 0.
- `y`: y coordinate of visual object. Default 0.
- `color`: object color
- `shape`: object shape
- `text`: object text
- `width`: object width 
- `height`: object height 
"""
mutable struct VisualObject <: AbstractVisualObject
    x::Float64
    y::Float64
    color::Symbol
    shape::Symbol
    text::String
    width::Float64
    height::Float64
end

function VisualObject(;
    x = 300.0,
    y = 300.0,
    color = :black,
    text = "",
    shape = :_,
    width = 30.0,
    height = 30.0
)
    return VisualObject(x, y, color, shape, text, width, height)
end

"""
    VisualLocation

Visual Location Module.

# Fields 

- `buffer::Array{T1,1}`: an array holding up to one chunk
- `state::B`: buffer state
- `iconic_memory::Array{T1,1}`: a temporary memory store for visible objects
"""
mutable struct VisualLocation{T1, B} <: Mod
    buffer::Array{T1, 1}
    state::B
    iconic_memory::Array{T1, 1}
end

function VisualLocation(; buffer = Chunk[])
    return VisualLocation(buffer, BufferState())
end

function VisualLocation(chunk::AbstractChunk, state)
    T = typeof(chunk)
    return VisualLocation([chunk], state, Vector{T}(undef, 1))
end

function VisualLocation(T::DataType, state)
    return VisualLocation(T(undef, 1), state, T(undef, 1))
end

function VisualLocation(chunks, state)
    c_chunks = copy(chunks)
    return VisualLocation(chunks, state, c_chunks)
end

abstract type AbstractRule end

"""
    Rule(;utlity=0.0, conditions, action)

A production rule object.

# Fields

- `utility=0.0`: utility of the production rule
- `initial_utility=0.0`: initial utility
- `utility_mean`=0.0: mean utility
- `utility_penalty=0.0`: mismatch penalty term for utility 
- `utlity_noise=0.0`: utility noise
- `conditions`: a function for checking conditions
- `action`: a function for performing an action
- `name`: name of production
"""
@concrete mutable struct Rule <: AbstractRule
    utility
    initial_utility
    utility_mean
    utility_penalty
    utility_noise
    conditions
    action
    can_pm
    name::String
end

"""
    Procedural

Procedural Memory Module object.

# Arguments

- `buffer`: an array holding up to one chunk
- `state`: buffer state
"""
mutable struct Procedural{R, B} <: Mod
    id::String
    rules::R
    state::B
end

function Procedural(; rules = Rule[], id = "")
    return Procedural(id, rules, BufferState())
end

function Procedural(rule::Rule, state, id)
    return Procedural(id, [rule], state)
end

function Procedural(T::DataType, state, id)
    return Procedural(id, T(undef, 1), state)
end

function utility_match(actr, condition)
    @error "a method must be defined for utility_match(actr::ACTR, condition)"
end

"""
    Goal(;chunk=Chunk()) 

Goal Module.

# Fields 

- `buffer`: an array holding up to one chunk
- `state`: buffer state
"""
mutable struct Goal{T1, B} <: Mod
    buffer::Array{T1, 1}
    state::B
end

function Goal(; buffer = Chunk[])
    return Goal(buffer, BufferState())
end

function Goal(chunk::AbstractChunk, state)
    return Goal([chunk], state)
end

function Goal(T::DataType, state)
    return Goal(T(undef, 1), state)
end

"""
    Motor(;chunk=Chunk()) 

Motor Module.

# Fields

- `buffer`: an array holding up to one chunk
- `state`: buffer state
- `mouse_position`: x,y coordinates of mouse position on screen
"""
mutable struct Motor{T1, B} <: Mod
    buffer::Array{T1, 1}
    state::B
    mouse_position::Vector{Float64}
end

function Motor(; buffer = Chunk[], mouse_position = [0.0, 0.0])
    return Motor(buffer, BufferState(), mouse_position)
end

function Motor(chunk::AbstractChunk, state, mouse_position)
    return Motor([chunk], state, mouse_position)
end

function Motor(T::DataType, state, mouse_position)
    return Motor(T(undef, 1), state, mouse_position)
end

mutable struct Scheduler
    time::Float64
end

Scheduler(; time = 0.0) = Scheduler(time)

abstract type AbstractACTR end

"""
    ACTR <: AbstractACTR

An object representing an ACTR model.

# Fields

- `name="model1"`: model name
- `declarative`: declarative memory module
- `imaginal`: imaginal memory module
- `visual`: visual module
- `goal`: goal module
- `visual_location`: visual location module
- `visicon`: a vector of VisualObjects available in the task
- `parms`: model parameters
- `scheduler`: event scheduler
- `rng': random number generator
"""
@concrete mutable struct ACTR <: AbstractACTR
    name
    declarative
    imaginal
    visual
    visual_location
    goal
    procedural
    motor
    visicon
    parms
    scheduler
    rng
end

Broadcast.broadcastable(x::ACTR) = Ref(x)
"""
    function ACTR(;
        name="model1", 
        declarative=Declarative(), 
        imaginal=Imaginal(), 
        goal = Goal(), 
        scheduler=Scheduler(), 
        visual=nothing, 
        visual_location=nothing, 
        procedural=nothing, 
        motor=nothing, 
        visicon=init_visicon(), 
        parm_type = Parms, 
        rng = Random.default_rng(),
        parms...) 

A constructor for creating an `ACTR` model object. 
    
# Keywords

- `name`: model name
- `declarative`: declarative memory module
- `imaginal`: imaginal memory module
- `visual`: visual module
- `goal`: goal module
- `visual_location`: visual location module
- `visicon`: a vector of VisualObjects available in the task
- `parms`: model parameters
- `scheduler`: event scheduler
- `rng': random number generator

# Example 

```@example 
using ACTRModels
parms = (noise=true, τ=-1.0)
chunks = [Chunk(;animal=:dog,name=:Sigma), Chunk(;animal=:rat,name=:Bonkers)]
declarative = Declarative(;memory=chunks)
actr = ACTR(;declarative, parms...)
```


"""
function ACTR(;
    name = "model1",
    declarative = Declarative(),
    imaginal = Imaginal(),
    goal = Goal(),
    scheduler = Scheduler(),
    visual = nothing,
    visual_location = nothing,
    procedural = nothing,
    motor = nothing,
    visicon = init_visicon(),
    parm_type = Parms,
    rng = Random.default_rng(),
    parms...
)
    parms′ = parm_type(; parms...)

    return ACTR(
        name,
        declarative,
        imaginal,
        visual,
        visual_location,
        goal,
        procedural,
        motor,
        visicon,
        parms′,
        scheduler,
        rng
    )
end

function init_visicon()
    return Dict{String, VisualObject}()
end
