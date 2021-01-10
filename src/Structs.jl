"""
**BufferState**

An object representing the state of the buffer.

- `busy`: busy if true
- `error`: error if true
- `empty`: empty if true

Constructor

````julia 
BufferState(;busy=false, error=false, empty=true)
````
"""
mutable struct BufferState
    busy::Bool
    error::Bool
    empty::Bool
end

BufferState(;busy=false, error=false, empty=true) = BufferState(busy, error, empty)

abstract type AbstractParms end

"""
Default parameter for the declarative memory module.

    * `d`: decay
    * `τ`: threshold
    * `s`: noise
    * `γ`: maximum associative strength
    * `blc`: base level constant
    * `δ`: mismatch penalty
    * `ter`: a constant for encoding and responding time
    * `mmpFun`: mismatch penalty function. Default substracts δ from each non-matching slot value
    * `lf:` latency factor parameter
    * `bll`: decay and learning on
    * `mmp`: mismatch penalty on
    * `sa`: spreading activatin on
    * `noise`: noise on
    * `misc`: NamedTuple of extra parameters
    * `filtered:` a list of slots that must absolutely match with mismatch penalty. isa and retrieval are included
        by default
"""
mutable struct Parms{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11} <: AbstractParms
    d::T1
    τ::T2
    s::T3
    γ::T4
    δ::T5
    blc::T6
    ter::T7
    mmpFun::T8
    lf::T9
    τ′::T10
    bll::Bool
    mmp::Bool
    sa::Bool
    noise::Bool
    misc::T11
end

function Parms(;d=.5, τ=0.0, s=.3, γ=0.0, δ=0.0, blc=0.0, ter=0.0, mmpFun=defaultFun,
    lf=1.0, τ′=zero(typeof(τ)), bll=false, mmp=false, sa=false, noise=false, args...)
    return Parms(d, τ, s, γ, δ, blc, ter, mmpFun, lf, τ′, bll, mmp, sa, noise , args.data)
end

"""
**Chunk**

A declarative memory chunk
* `N`: number of uses
* `L`: lifetime of chunk
* `time_created`: time at which the chunk was created
* `k`: number of chunks in recent set (k=1 is sufficient)
* `act`: total activation
* `act_blc`: base level constant component of activation
* `act_bll`: base level learning component of activation
* `act_pm`: partial matching component of activation
* `act_sa`: spreading activation component of activation
* `act_noise`: noise component of activation
* `slots`: chunk slot-value pairs
* `reps`: number of identical chunks. This can be used in simple cases to speed up the code.
* `recent`: time stamps for k recent retrievals
* `lags`: lags for recent retrievals (L - recent)
* `bl`: baselevel constant added to chunks activation

Example:
````julia
chunk = Chunk(;time_created=4.0, person=:hippie, place=:park)
````
"""
mutable struct Chunk{T1,T2}
  N::Int
  L::Float64
  time_created::Float64
  k::Int
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

function Chunk(;N=1, L=1.0, time_created=0.0, k=1, act=0.0, recent=[0.0],
    reps=0, lags=Float64[], bl=zero(typeof(act)), slots...)
    T = typeof(act)
    act_pm = zero(T)
    act_blc = zero(T)
    act_bll = zero(T)
    act_noise = zero(T)
    act_sa = zero(T)
    return Chunk(N, L, time_created, k, act, act_blc, act_bll, act_pm, act_sa, act_noise,
        slots.data, reps, recent, lags, bl)
end

function Chunk(dynamic::Bool; N=1, L=1.0, time_created=0.0, k=1, act=0.0, recent=[0.0],
    reps=0, lags=Float64[], bl=zero(typeof(act)), slots...)
    T = typeof(act)
    act_pm = zero(T)
    act_blc = zero(T)
    act_bll = zero(T)
    act_noise = zero(T)
    act_sa = zero(T)
    slots = Dict(k=>v for (k,v) in pairs(slots))
    return Chunk(N, L, time_created, k, act, act_blc, act_bll, act_pm, act_sa, act_noise,
        slots, reps, recent, lags, bl)
end

Broadcast.broadcastable(x::Chunk) = Ref(x)

abstract type Mod end

"""
**Declarative***

Declarative Memory Module
- `memory`: array of chunks
- `filtered`:
- `buffer`: an array containing one chunk
- `state`: buffer state

Constructor:
````julia 
Declarative(;memory=Chunk[], filtered=(:isa,:retrieved))
````

Example:
````julia
declarative = Declarative(memory=chunks)
````
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
**defaultFun**

A default function for mismatch penalty. Subtracts δ if
slot does not exist or slot value does not match
* `memory`: declarative memory object
* `chunk`: memory chunk object
* `request`: `NamedTuple` of slot-value pairs for the retrieval request

Function Signature
````julia 
defaultFun(actr, chunk; request...)
````
"""
function defaultFun(actr, chunk; request...)
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
**Imaginal**

Imaginal Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state
- `ω`: fan weight. Default is 1.
- `denoms`: cached value for the denominator of the fan calculation

Constructor
````julia 
Imaginal(;chunk=Chunk(), ω=1.0, denoms=Int64[]) 
````
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
**Visual**

Visual Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state

Constructor
````julia 
Visual(;chunk=Chunk()) 
````
"""
mutable struct Visual{T1} <: Mod
    buffer::Array{T1,1}
    state::BufferState
    focus::Vector{Float64}
end

Visual(;buffer=Chunk[]) = Visual(buffer, BufferState(), fill(0.0,2))
Visual(chunk::Chunk, state, focus) = Visual([chunk], state, focus)
Visual(T::DataType, state, focus) = Visual(T(undef,1), state, focus)

"""
**VisualObject**

Visual Location Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state

Constructor
````julia 
VisualObject(;x=300.0, y=300.0, color=:black, text="", shape=:_, width=30.0, height=30.0) 
````
"""
mutable struct VisualObject
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
VisualLocation(;chunk=Chunk()) 
````
"""
mutable struct VisualLocation{T1} <: Mod
    buffer::Array{T1,1}
    state::BufferState
    visicon::Vector{VisualObject}
    iconic_memory::Array{T1,1}
end

function VisualLocation(;buffer=Chunk[], visicon=VisualObject[]) 
    VisualLocation(buffer, BufferState(), visicon)
end

function VisualLocation(chunk::Chunk, state, visicon)
    T = typeof(chunk)
     VisualLocation([chunk], state, visicon, Vector{T}(undef,1))
end

function VisualLocation(T::DataType, state, visicon)
    VisualLocation(T(undef,1), state, visicon, T(undef,1))
end

function VisualLocation(chunks, state, visicon)
    c_chunks = copy(chunks)
    VisualLocation(chunks, state, visicon, c_chunks)
end

"""
**Rule**

A production rule.

- `utility`: utility of the production rule
- `conditions`: a function for checking conditions
- `action`: a function for performing an action

Constructor
````julia 
Rule(;utlity=0.0, conditions, action)
````
"""
mutable struct Rule{C,A}
    utility::Float64 
    conditions::C
    action::A
end

function Rule(;utility=0.0, conditions, actr, task, action, args=(), kwargs...) 
     Rule(utility, map(x->()->x(actr, args...; kwargs...), conditions), ()->action(actr, task, args...; kwargs...))
end

"""
**Procedural**

Procedural Memory Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state

Constructor
````julia 
Procedural(;chunk=Chunk()) 
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

"""
**Goal**

Goal Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state

Constructor
````julia 
Goal(;chunk=Chunk()) 
````
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
**Motor**

Motor Module.
- `buffer`: an array holding up to one chunk
- `state`: buffer state

Constructor
````julia 
Motor(;chunk=Chunk()) 
````
"""
mutable struct Motor{T1} <: Mod
    buffer::Array{T1,1}
    state::BufferState
end

function Motor(;buffer=Chunk[]) 
    Motor(buffer, BufferState())
end

function Motor(chunk::Chunk, state)
    Motor([chunk], state)
end

function Motor(T::DataType, state)
    Motor(T(undef,1), state)
end

abstract type AbstractACTR end
"""
**ACTR**

ACTR model object
- `declarative`: declarative memory module
- `imaginal`: imaginal memory module
- `parms`: model parameters
-  `scheduler`: event scheduler

Constructor
````julia 
ACTR(;T=Parms, declarative=Declarative(), imaginal=Imaginal(), 
    scheduler=nothing, parms...)
````
"""
mutable struct ACTR{T1,T2,T3,T4,T5,T6,T7,T8,T9} <: AbstractACTR
    declarative::T1
    imaginal::T2
    visual::T3
    visual_location::T4
    goal::T5
    procedural::T6
    motor::T7
    parms::T8
    scheduler::T9
end

Broadcast.broadcastable(x::ACTR) = Ref(x)

function ACTR(;declarative=Declarative(), imaginal=Imaginal(), 
    goal = Goal(), scheduler=nothing, visual=nothing, visual_location=nothing, 
    procedural=nothing, motor=nothing, parms...) 
    parms′ = Parms(;parms...)
    ACTR(declarative, imaginal, visual, visual_location, goal, procedural, motor, parms′, scheduler)
end

abstract type AbstractTask end

