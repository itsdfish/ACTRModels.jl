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

function run_trial!(task, model)
    isi = 1.0#sample_isi(task)
    description = "present stimulus"
    register!(task.scheduler, present_stimulus, after, isi, task, model;
        description)
end

function press_key!(task::PVT, model, key)
    if key == "sb"
        empty!(task.screen)
        if task.trial < task.n_trials
            task.trial += 1
            run_trial!(task, model)
        else
            stop!(task.scheduler)
        end
    end
end

