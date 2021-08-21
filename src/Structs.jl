"""
    BufferState(;busy, error, empty)

An object representing the state of the buffer.

# Fields

- `busy=false`: busy if true
- `error=false`: error if true
- `empty=true`: empty if true
"""
mutable struct BufferState
    busy::Bool
    error::Bool
    empty::Bool
end

BufferState(;busy=false, error=false, empty=true) = BufferState(busy, error, empty)

abstract type AbstractParms end

"""
    Parms(; kwargs...) -> Parms 

ACT-R parameters with default values. Default values are overwritten with keyword arguments.

# Fields

- `d=0.5`: activation decay
- `τ=0.0`: retrieval threshold
- `s=0.2`: logistic scalar for activation noise.
- `γ=1.6`: maximum associative strength
- `blc=0.0`: base level constant
- `δ=0.0`: mismatch penalty
- `ter=0.0`: a constant for encoding and responding time
- `mmp_fun`: a mismatch penalty function. By default, `mmp_fun` subtracts `δ` from each non-matching slot value
- `sa_fun`: a function for spreading activation which requires arguments for actr and chunk
- `select_rule`: a function for selecting production rule
- `lf=1.0:` latency factor parameter
- `bll=false`: base level learning on
- `mmp=false`: mismatch penalty on
- `sa=false`: spreading activatin on
- `noise=false`: noise on
- `misc`: `NamedTuple` of extra parameters
- `filtered:` a list of slots that must absolutely match with mismatch penalty. `isa` and `retrieval` are included
    by default
"""
@concrete mutable struct Parms <: AbstractParms
    d
    τ
    s
    γ
    δ
    blc
    ter
    mmp_fun
    sa_fun
    select_rule
    lf
    τ′
    bll::Bool
    mmp::Bool
    sa::Bool
    noise::Bool
    misc
end

function Parms(;
    d = .5,
    τ = 0.0, 
    s = .3,
    γ = 0.0,
    δ = 0.0,
    blc = 0.0,
    ter = 0.0,
    mmp_fun = default_penalty,
    sa_fun = spreading_activation!,
    select_rule = exact_match,
    lf = 1.0,
    τ′ = τ,
    bll = false,
    mmp = false,
    sa = false,
    noise = false,
    kwargs...
    )
    
    Parms(
        d,
        τ,
        s,
        γ,
        δ,
        blc,
        ter,
        mmp_fun,
        sa_fun,
        select_rule,
        lf,
        τ′,
        bll,
        mmp,
        sa,
        noise,
        NamedTuple(kwargs)
    )
end

function Base.show(io::IO, ::MIME"text/plain", parms::Parms)
    values = [getfield(parms, f) for f in fieldnames(Parms)]
    values = map(x->typeof(x)== Bool ? string(x) : x, values)
    return pretty_table(
        values;
        title="Model Parameters",
        row_name_column_title="Parameter",
        compact_printing=false,
        header=["Value"],
        row_name_alignment=:l,
        row_names=[fieldnames(Parms)...],
        formatters=ft_printf("%5.2f"),
        alignment=:l,
    )
end

"""
    Chunk(; kwargs...) -> Chunk

A declarative memory chunk.

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
mutable struct Chunk{T1,T2}
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
  recent::Array{Float64,1}
  lags::Array{Float64,1}
  bl::T2
end

function Chunk(;
    N=1,
    L=1.0,
    time_created=0.0,
    k=1, 
    act=0.0, 
    recent=[0.0],
    reps=0, 
    lags=Float64[], 
    bl=zero(typeof(act)),
    slots...
    )
    T = typeof(act)
    act_mean = zero(T)
    act_pm = zero(T)
    act_blc = zero(T)
    act_bll = zero(T)
    act_noise = zero(T)
    act_sa = zero(T)
    return Chunk(N, L, time_created, k, act_mean, act, act_blc, act_bll, act_pm, act_sa, act_noise,
        NamedTuple(slots), reps, recent, lags, bl)
end

"""
    Chunk(; kwargs...) -> Chunk

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
function Chunk(dynamic::Bool; 
    N=1,
    L=1.0,
    time_created=0.0,
    k=1, 
    act=0.0, 
    recent=[0.0],
    reps=0, 
    lags=Float64[], 
    bl=zero(typeof(act)),
    slots...
    )
    T = typeof(act)
    act_mean = zero(T)
    act_pm = zero(T)
    act_blc = zero(T)
    act_bll = zero(T)
    act_noise = zero(T)
    act_sa = zero(T)
    slots = Dict(k=>v for (k,v) in pairs(slots))
    return Chunk(N, L, time_created, k, act_mean, act, act_blc, act_bll, act_pm, act_sa, act_noise,
        slots, reps, recent, lags, bl)
end

Broadcast.broadcastable(x::Chunk) = Ref(x)

const chunk_fields = (:slots,:N,:L,:time_created,:recent,:act_mean,:act,:act_blc,:bl,:act_bll,:act_pm,:act_noise)

function chunk_values(chunk)
    values = [getfield(chunk, f) for f in chunk_fields]
    return map(x->typeof(x)== Bool ? string(x) : x, values)
end

function Base.show(io::IO, ::MIME"text/plain", chunk::Chunk)
    values = chunk_values(chunk)
    return pretty_table(
        values;
        title="Chunk",
        row_name_column_title="Property",
        compact_printing=false,
        header=["Value"],
        row_name_alignment=:l,
        row_names=[chunk_fields...],
        formatters=ft_printf("%5.2f"),
        alignment=:l,
    )
end

function Base.show(io::IO, ::MIME"text/plain", chunks::Vector{<:Chunk})
    table = [chunk_values(chunk) for chunk in chunks]
    table = hcat(table...)
    table = permutedims(table)
    return pretty_table(
        table;
        title="Chunks",
        # row_name_column_title="Parameter",
        compact_printing=false,
        header=[chunk_fields...],
        row_name_alignment=:l,
        formatters=ft_printf("%5.2f"),
        alignment=:l,
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
mutable struct Declarative{T1,T2} <: Mod
    memory::Array{T1,1}
    filtered::T2
    buffer::Array{T1,1}
    state::BufferState
end

function Declarative(;memory=Chunk[], filtered=(:isa,:retrieved))
    state = BufferState()
    return  Declarative(memory, filtered, typeof(memory)(undef,1), state)
end

"""
    default_penalty(actr, chunk; request...)

A default function for mismatch penalty. Subtracts δ if
slot does not exist or slot value does not match

# Arguments 

- `actr`: an ACTR model object
- `chunk`: memory chunk object

# Keywords

- `request`: a variable size collection of slot-value pairs for the retrieval request
"""
function default_penalty(actr, chunk; request...)
    slots = chunk.slots
    p = 0.0; δ = actr.parms.δ
    for (k,v) in request
        if !(k ∈ keys(slots)) || (slots[k] != v)
            p += δ
        end
     end
     return p
end

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
mutable struct Imaginal{T1,T2} <: Mod
    buffer::Array{T1,1}
    state::BufferState
    ω::T2
    denoms::Vector{Int64}
end

function Imaginal(;buffer=Chunk[], ω=1.0, denoms=Int64[]) 
    state = BufferState()
    Imaginal(buffer, state, ω, denoms)
end


Imaginal(chunk::Chunk, state, ω, denoms) = Imaginal([chunk], state, ω, denoms)
Imaginal(T::DataType, state, ω, denoms) = Imaginal(T(undef,1), state, ω, denoms)

"""
    Visual(;chunk=Chunk()) 

Visual Module.

# Fields 

- `buffer`: an array holding up to one chunk
- `state`: buffer state
- `focus`: coordinates of visual attention
"""
mutable struct Visual{T1} <: Mod
    buffer::Array{T1,1}
    state::BufferState
    focus::Vector{Float64}
end

Visual(;buffer=Chunk[]) = Visual(buffer, BufferState(), fill(0.0,2))
Visual(chunk::Chunk, state, focus) = Visual([chunk], state, focus)
Visual(T::DataType, state, focus) = Visual(T(undef,1), state, focus)


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

function VisualObject(;x=300.0, y=300.0, color=:black, text="", shape=:_, width=30.0, height=30.0)
    return VisualObject(x, y, color, shape, text, width, height)
end

"""
**VisualLocation**

Visual Location Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state

Constructor
````julia 
VisualLocation(;buffer=Chunk[]) 

VisualLocation(chunk::Chunk, state)

VisualLocation(T::DataType, state)

VisualLocation(chunks, state)
````
"""
mutable struct VisualLocation{T1} <: Mod
    buffer::Array{T1,1}
    state::BufferState
    iconic_memory::Array{T1,1}
end

function VisualLocation(;buffer=Chunk[]) 
    VisualLocation(buffer, BufferState())
end

function VisualLocation(chunk::Chunk, state)
    T = typeof(chunk)
     VisualLocation([chunk], state, Vector{T}(undef,1))
end

function VisualLocation(T::DataType, state)
    VisualLocation(T(undef,1), state, T(undef,1))
end

function VisualLocation(chunks, state)
    c_chunks = copy(chunks)
    VisualLocation(chunks, state, c_chunks)
end

"""
    Rule(;utlity=0.0, conditions, action)

A production rule object.

# Fields

- `utility`: utility of the production rule
- `conditions`: a function for checking conditions
- `action`: a function for performing an action
- `name`: name of production
"""
@concrete mutable struct Rule
    utility::Float64 
    conditions
    action
    name::String
end

function Rule(;utility=0.0, conditions, name="", actr, task, action, args=(), kwargs...) 
    Rule(utility, ()->conditions(actr, args...; kwargs...), 
    ()->action(actr, task; kwargs...), name)
end

"""
**Procedural**

Procedural Memory Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state

Constructor
````julia 
Procedural(;chunk=Chunk())

Procedural(;rules=Rule[], id="")  

Procedural(rule::Rule, state, id)

Procedural(T::DataType, state, id)
````
"""
mutable struct Procedural{R} <: Mod
    id::String
    rules::R
    state::BufferState
end

function Procedural(;rules=Rule[], id="") 
    Procedural(id, rules, BufferState())
end

function Procedural(rule::Rule, state, id)
    Procedural(id, [rule], state)
end

function Procedural(T::DataType, state, id)
    Procedural(id, T(undef,1), state)
end

function get_matching_rules(actr)
    return filter(r->match(r), get_rules(actr))
end

get_rules(actr) = actr.procedural.rules

function exact_match(actr)
    rules = get_matching_rules(actr)
    shuffle!(rules)
    return rules
end

function match(rule)
    return rule.conditions()
end

"""
    Goal(;chunk=Chunk()) 

Goal Module.

# Fields 

- `buffer`: an array holding up to one chunk
- `state`: buffer state
"""
mutable struct Goal{T1} <: Mod
    buffer::Array{T1,1}
    state::BufferState
end

function Goal(;buffer=Chunk[]) 
    Goal(buffer, BufferState())
end

function Goal(chunk::Chunk, state)
    Goal([chunk], state)
end

function Goal(T::DataType, state)
    Goal(T(undef,1), state)
end

"""
    Motor(;chunk=Chunk()) 

Motor Module.

# Fields
- `buffer`: an array holding up to one chunk
- `state`: buffer state
- `mouse_position`: x,y coordinates of mouse position on screen
"""
mutable struct Motor{T1} <: Mod
    buffer::Array{T1,1}
    state::BufferState
    mouse_position::Vector{Float64}
end

function Motor(;buffer=Chunk[], mouse_position=[0.0,0.0]) 
    Motor(buffer, BufferState(), mouse_position)
end

function Motor(chunk::Chunk, state, mouse_position)
    Motor([chunk], state, mouse_position)
end

function Motor(T::DataType, state, mouse_position)
    Motor(T(undef,1), state, mouse_position)
end

abstract type AbstractACTR end

"""
ACTR(; kwargs...) -> ACTR

ACTR model object

# Fields

- `declarative`: declarative memory module
- `imaginal`: imaginal memory module
- `visual`: visual module
- `goal`: goal module
- `visual_location`: visual location module
- `visicon`: a vector of VisualObjects available in the task
- `parms`: model parameters
- `scheduler`: event scheduler

# Example 
````julia 
parms = (noise=true, τ=-1.0)
chunks = [Chunk(;animal=:dog,name=:Sigma), Chunk(;animal=:rat,name=:Bonkers)]
declarative = Declarative(;memory=chunks)
actr = ACTR(;declarative, parms...)
````
"""
@concrete mutable struct ACTR <: AbstractACTR
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
end

Broadcast.broadcastable(x::ACTR) = Ref(x)

function ACTR(;declarative=Declarative(), imaginal=Imaginal(), 
    goal = Goal(), scheduler=nothing, visual=nothing, visual_location=nothing, 
    procedural=nothing, motor=nothing, visicon=init_visicon(), parms...) 
    parms′ = Parms(;parms...)
    ACTR(declarative, imaginal, visual, visual_location, goal, procedural, motor, visicon, parms′, scheduler)
end

function init_visicon()
    Dict{String,VisualObject}()
end