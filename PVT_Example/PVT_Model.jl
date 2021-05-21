###################################################################################################
#                                        Production Conditions
###################################################################################################
function can_attend()
    c1(actr, args...; kwargs...) = !isempty(actr.visual_location.buffer)
    c2(actr, args...; kwargs...) = !actr.visual.state.busy
    return (c1,c2)
end

function can_wait()
    c1(actr, args...; kwargs...) = isempty(actr.visual_location.buffer)
    c2(actr, args...; kwargs...) = isempty(actr.visual.buffer)
    c3(actr, args...; kwargs...) = !actr.visual.state.busy
    c4(actr, args...; kwargs...) = !actr.motor.state.busy
    return (c1,c2,c3,c4)
end

function can_respond()
    c1(actr, args...; kwargs...) = !isempty(actr.visual.buffer)
    c2(actr, args...; kwargs...) = !actr.motor.state.busy
    return (c1,c2)
end
###################################################################################################
#                                        Production Actions
###################################################################################################
function wait_action(actr, args...; kwargs...)
    description = "Wait"
    register!(actr.scheduler, ()->(), now; description)
    return nothing
end

function attend_action(actr, task, args...; kwargs...)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end

function respond_action(actr, task, args...; kwargs...)
    clear_buffer!(actr.visual)
    key = "sb"
    responding!(actr, task, key)
    return nothing
end

function clear_buffer!(mod::Mod)
    empty!(mod.buffer)
end

function add_chunk!(mod::Mod, chunk)
    clear_buffer!(mod)
    push!(mod.buffer, chunk)
end

function add_to_visicon!(actr, vo; stuff=false) 
    push!(actr.visual_location.visicon, deepcopy(vo))
    if stuff 
       chunk = vo_to_chunk(actr, vo)
       add_chunk!(actr.visual_location, chunk)
    end
    return nothing 
end

vo_to_chunk(vo=VisualObject()) = Chunk(;color=vo.color, text=vo.text)

function vo_to_chunk(actr, vo)
    time_created = get_time(actr)
    return Chunk(;time_created, color=vo.color, text=vo.text)
end