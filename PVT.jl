using Revise, DiscreteEventsLite, DataStructures, ACTRModels


import DiscreteEventsLite: run!, last_event!, is_running, print_event

mutable struct PVT{T,G} <: AbstractTask 
    n_trials::Int
    trial::Int 
    lb::Float64
    ub::Float64 
    width::Float64
    hight::Float64
    scheduler::T
    screen::Vector{VisualObject}
    gui::G
    display_on::Bool
end

function PVT(;n_trials=10, trial=1, lb=2.0, ub=10.0, width=600.0, height=600.0, scheduler=nothing, 
    screen=Vector{VisualObject}(), gui=nothing, display_on=false)
    return PVT(n_trials, trial, lb, ub, width, height, scheduler, screen, gui, display_on)
end

function start!(task::PVT, model)
    run_trial!(task, model)
end

function start!(model)
    register!(model.scheduler, ()->(), now; description="Starting")
end

function sample_isi(task)
    return rand(Uniform(task.lb, task.ub))
end

function present_stimulus(task, model)
    vo = VisualObject()
    add_to_visicon!(model, vo; stuff=true)
    push!(task.screen, vo)
end

function add_to_visicon!(actr, vo; stuff=false) 
    push!(actr.visual_location.visicon, deepcopy(vo))
    if stuff 
       buffer = get_buffer(actr, :visual_location)
       empty!(buffer)
       chunk = vo_to_chunk(actr, vo)
       push!(buffer, chunk)
    end
    return nothing 
end

function vo_to_chunk(actr, vo)
    time_created = get_time(actr)
    return Chunk(;time_created, color=vo.color, text=vo.text)
end

function press_key!(task::PVT, model, key)
    if key == "sb"
        empty!(task.screen)
        if task.trial < task.n_trials
            task.trial += 1
            run_trial!(task, model)
        end
    end
end

function run_trial!(task, model)
    isi = 1.0#sample_isi(task)
    description = "present stimulus"
    register!(task.scheduler, present_stimulus, after, isi, task, model;
        description)
end

function can_attend()
    c1(actr, args...; kwargs...) = !isempty(actr.visual_location.buffer)
    c2(actr, args...; kwargs...) = !actr.visual.state.busy
    return (c1,c2)
end

function can_wait()
    c1(actr, args...; kwargs...) = isempty(actr.visual_location.buffer)
    return (c1,)
end

function can_respond()
    c1(actr, args...; kwargs...) = !isempty(actr.motor.buffer)
    c2(actr, args...; kwargs...) = !actr.motor.state.busy
    return (c1,c2)
end

function wait_action(actr, args...; kwargs...)
    description = "Wait"
    register!(actr.scheduler, ()->(), now; description)
    return nothing
end

function respond_action(actr, task, args...; kwargs...)
    actr.motor.state.busy = true
    description = "Respond"
    tΔ = rand(Uniform(.05,.70))
    register!(actr.scheduler, respond, after, tΔ , actr, task;
        description)
    return nothing
end

function attend_action(actr, task, args...; kwargs...)
    actr.motor.state.busy = true
    description = "Attend"
    tΔ = rand(Uniform(.05,.70))
    register!(actr.scheduler, attend!, after, tΔ , actr, task; description)
    return nothing
end

scheduler = Scheduler(;trace=true)
task = PVT(;scheduler)
procedural = Procedural()
visual_location = VisualLocation()
visual = Visual()
motor = Motor()
actr = ACTR(;scheduler, procedural, visual_location, visual, motor)
conditions = can_attend()
rule1 = Rule(;conditions, action=attend_action, actr, task)
push!(procedural.rules, rule1)
conditions = can_wait()
rule2 = Rule(;conditions, action=wait_action, actr, task)
push!(procedural.rules, rule2)
conditions = can_respond()
rule3 = Rule(;conditions, action=respond_action, actr, task)
push!(procedural.rules, rule3)
run!(actr, task, 1.1)