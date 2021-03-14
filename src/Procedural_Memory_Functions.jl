function match(rule::Rule)
    all(c->c(), rule.conditions)
end

function fire!(actr)
    actr.procedural.state.busy ? (return nothing) : nothing
    rules = select_rule(actr)
    if !isempty(rules)
        rule = rules[1]
        description = "Selected "*rule.name
        tΔ = .05#rand(Uniform(.03, .07))
        resolving(actr, true)
        f(r, a, v) = (resolving(a, v), r.action()) 
        register!(actr.scheduler, f, after, tΔ, rule, actr, false; description)
    end
    return nothing 
end

resolving(actr, v) = actr.procedural.state.busy = v

function select_rule(actr)
    rules = get_matching_rules(actr)
    shuffle!(rules)
    return rules
end

function get_matching_rules(actr)
    return filter(r->match(r), get_rules(actr))
end

get_rules(actr) = actr.procedural.rules

function compute_utility!(actr)
    #@unpack σu, δu = actr.parms
    δu = 1.0
    σu = .5
    for r in get_rules(actr)
        c = count_mismatches(r)
        u = rand(Normal(c*δu, σu))
        r.utility = u
    end
end
  
function count_mismatches(rule)
    return count(c->!c(), rule.conditions)
end

function attend!(actr, chunk, args...; kwargs...)
    visual = get_buffer(actr, :visual)
    push!(visual, chunk)
    actr.visual.state.busy = false
    return nothing 
end

function respond(actr, task, key)
    actr.motor.state.busy = false
    press_key!(task, actr, key)
end
