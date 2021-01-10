function match(rule::Rule)
    all(c->c(), rule.conditions)
end

function fire!(model)
    model.procedural.state.busy ? (return nothing) : nothing
    rules = select_rule(model)
    if !isempty(rules)
        description = "Conflict Resolution"
        tΔ = .05#rand(Uniform(.03, .07))
        model.procedural.state.busy = true
        register!(model.scheduler, rules[1].action, after, tΔ; description)
        register!(model.scheduler, ()-> model.procedural.state.busy = false, after, tΔ)
    end
    return nothing 
end

function select_rule(model)
    return get_matching_rules(model)
end

function get_matching_rules(model)
    rules = Rule[]
    for r in get_rules(model)
        if match(r)
            push!(rules, r)
        end
    end
    return rules
end

get_rules(actr) = actr.procedural.rules

function compute_utility!(model)
    #@unpack σu, δu = model.parms
    δu = 1.0
    σu = .5
    for r in get_rules(model)
        c = count_mismatches(r)
        u = rand(Normal(c*δu, σu))
        r.utility = u
    end
end
  
function count_mismatches(rule)
    return count(c->!c(), rule.conditions)
end

function attend!(actr, args...; kwargs...)
    location = get_buffer(actr, :visual_location)
    visual = get_buffer(actr, :visual)
    push!(visual, location...)
    return nothing 
end

function respond(model, task)
    model.procedural.state.busy = false
    press_key!(task, "sb")
end
