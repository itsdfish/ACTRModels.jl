function fire!(actr)
    actr.procedural.state.busy ? (return nothing) : nothing
    rules = actr.parms.select_rule(actr)
    if !isempty(rules)
        rule = rules[1]
        description = "Selected "*rule.name
        tΔ = rnd_time(.05)
        resolving(actr, true)
        f(r, a, v) = (resolving(a, v), r.action()) 
        register!(actr.scheduler, f, after, tΔ, rule, actr, false; description)
    end
    return nothing 
end

resolving(actr, v) = actr.procedural.state.busy = v

function compute_utility!(actr)
    #@unpack σu, δu = actr.parms
    δu = 1.0
    σu = .5
    for r in get_rules(actr)
        c = count_mismatches(r)
        u = rand(Normal(c * δu, σu))
        r.utility = u
    end
end
  
function count_mismatches(rule)
    return count(c->!c(), rule.conditions)
end

function attending!(actr, chunk, args...; kwargs...)
    actr.visual.state.busy = true
    description = "Attend"
    tΔ = rnd_time(.085)
    register!(actr.scheduler, attend!, after, tΔ , actr, chunk; description)
end

function attend!(actr, chunk, args...; kwargs...)
    actr.visual.state.busy = false
    actr.declarative.state.empty = false
    add_chunk!(actr.visual, chunk)
    return nothing 
end

function retrieving(actr, args...; request...)
    actr.desclarative.state.busy = true
    description = "Retrieve"
    cur_time = get_time(actr)
    chunk = retrieve(actr, cur_time; request...)
    tΔ = compute_RT(actr, chunk)
    register!(actr.scheduler, retrieve!, after, tΔ , actr, chunk; description)
end

function retrieve!(actr, chunk, args...; kwargs...)
    actr.declarative.state.busy = false
    actr.declarative.state.empty = false
    if isempty(chunk)
        actr.declarative.state.error = true
    else
        add_chunk!(actr.declarative, chunk[1])
    end
    return nothing 
end

function responding!(actr, task, key, args...; kwargs...)
    actr.motor.state.busy = true
    description = "Respond"
    tΔ = rnd_time(.060)
    register!(actr.scheduler, respond, after, tΔ , actr, task, key;
        description)
end

function respond(actr, task, key)
    actr.motor.state.busy = false
    press_key!(task, actr, key)
end

rnd_time(μ) = rand(Uniform(μ * (2/3), μ * (4/3)))
