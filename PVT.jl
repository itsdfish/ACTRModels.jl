using Revise, DiscreteEventsLite, DataStructures, ACTRModels


import DiscreteEventsLite: run!, last_event!, is_running, print_event

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

function start!(task::PVT)
    run_trial!(task)
end

function start!(model)
    register!(model.scheduler, ()->(), now; description="Starting")
end

function sample_isi(task)
    return rand(Uniform(task.lb, task.ub))
end

function present_stimulus(task)
    push!(task.screen, VisualObject())
end

function press_key!(task::PVT, key)
    if key == "sb"
        empty!(task.screen)
        if task.trial < task.n_trials
            task.trial += 1
            run_trial!(task)
        end
    end
end

function run_trial!(task)
    isi = sample_isi(task)
    description = "present stimulus"
    register!(task.scheduler, present_stimulus, after, isi, task;
        description)
end

function get_time(task)
    return task.scheduler.time
end

function check_conditions!(model, task)
    if !model.busy && !isempty(task.screen)
        model.busy = true
        description = "Respond"
        tΔ = rand(Uniform(.240,.280))
        register!(task.scheduler, respond, after, tΔ , model, task;
            description)
    end
end

function respond(model, task)
    model.busy = false
    press_key!(task, "sb")
end

mutable struct Model{T}
    busy::Bool
    scheduler::T
end

Model(;busy=false, scheduler=nothing) = Model(busy, scheduler)


function run!(model, task::AbstractTask, until=Inf)
    s = task.scheduler
    last_event!(s, until)
    start!(task)
    start!(model)
    check_conditions!(model, task)
    while is_running(s, until)
        event = dequeue!(s.events)
        new_time = event.time
        s.time = new_time
        event.fun()
        check_conditions!(model, task)
        s.store ? push!(s.complete_events, event) : nothing
        s.trace ? print_event(event) : nothing
    end
    s.trace && !s.running ? print_event(s.time, "", "stopped") : nothing
    return nothing
end

scheduler = Scheduler(;trace=true)
pvt = PVT(;scheduler)
model = Model(;scheduler)
run!(model, pvt)