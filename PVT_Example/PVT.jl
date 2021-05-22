"""
** PVT **

- `n_trials`: number of trials
- `trial`: current trial
- `lb`: ISI lower bound
- `ub`: ISI upper bound
- `width`: screen width
- `height`: screen height
- `scheduler`: event scheduler
- `screen`: visual objects on screen
- `canvas`: GTK canvas
- `window`: GTK window
- `visible`: GUI visible
- `speed`: real time speed

Function Signature 

````julia
PVT(;n_trials=10, trial=1, lb=2.0, ub=10.0, width=600.0, height=600.0, scheduler=nothing, 
    screen=Vector{VisualObject}(), window=nothing, canvas=nothing, visible=false, speed=1.0)
````
"""
mutable struct PVT{T,W,C} <: AbstractTask 
    n_trials::Int
    trial::Int 
    lb::Float64
    ub::Float64 
    width::Float64
    hight::Float64
    scheduler::T
    screen::Vector{VisualObject}
    canvas::C
    window::W
    visible::Bool
    realtime::Bool
    speed::Float64
end

function PVT(;n_trials=10, trial=1, lb=2.0, ub=10.0, width=600.0, height=600.0, scheduler=nothing, 
    screen=Vector{VisualObject}(), window=nothing, canvas=nothing, visible=false, realtime=false,
    speed=1.0)
    visible ? ((canvas,window) = setup_window(width)) : nothing
    visible ? Gtk.showall(window) : nothing
    return PVT(n_trials, trial, lb, ub, width, height, scheduler, screen, canvas, window, visible,
        realtime, speed)
end

function setup_window(width)
	canvas = @GtkCanvas()
    window = GtkWindow(canvas, "PVT", width, width)
    Gtk.visible(window, true)
    @guarded draw(canvas) do widget
        ctx = getgc(canvas)
        rectangle(ctx, 0.0, 0.0, width, width)
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
	return canvas,window
end

function draw_object!(task)
    c = task.canvas
    w = task.width
	x = w/2
	y = w/2
    letter = "X"
    @guarded draw(c) do widget
        ctx = getgc(c)
        select_font_face(ctx, "Arial", Cairo.FONT_SLANT_NORMAL,
             Cairo.FONT_WEIGHT_BOLD);
        set_font_size(ctx, 36)
        set_source_rgb(ctx, 0, 0, 0)
        extents = text_extents(ctx, letter)
        x′ = x - (extents[3]/2 + extents[1])
        y′ = y - (extents[4]/2 + extents[2])
        move_to(ctx, x′, y′)
        show_text(ctx, letter)
    end
    Gtk.showall(c)
    return nothing
end

function clear!(task)
    c = task.canvas
    w = task.width
    @guarded draw(c) do widget
        ctx = getgc(c)
        rectangle(ctx, 0, 0, w, w)
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

function start!(task::PVT, model)
    run_trial!(task, model)
end

function sample_isi(task)
    return rand(Uniform(task.lb, task.ub))
end

function present_stimulus(task, model)
    vo = VisualObject()
    add_to_visicon!(model, vo; stuff=true)
    push!(task.screen, vo)
    task.visible ? draw_object!(task) : nothing
end

function run_trial!(task, model)
    isi = sample_isi(task)
    description = "present stimulus"
    register!(task.scheduler, present_stimulus, after, isi, task, model;
        description)
end

function press_key!(task::PVT, model, key)
    if key == "sb"
        empty!(task.screen)
        task.visible ? clear!(task) : nothing
        if task.trial < task.n_trials
            task.trial += 1
            run_trial!(task, model)
        else
            stop!(task.scheduler)
        end
    end
end