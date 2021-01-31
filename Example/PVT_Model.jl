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
    actr.visual.state.busy = true
    description = "Attend"
    tΔ = .085#rand(Uniform(.050,.070))
    buffer = get_buffer(actr, :visual_location)
    chunk = deepcopy(buffer[1])
    empty!(actr.visual_location.buffer)
    register!(actr.scheduler, attend!, after, tΔ , actr, chunk; description)
    # description = "Add Chunk to Motor Buffer"
    #tΔ += eps()
    # chunk = deepcopy(chunk)
    # register!(actr.scheduler, add_to_motor_buffer!, after, tΔ , actr, chunk; description)
    return nothing
end

function respond_action(actr, task, args...; kwargs...)
    actr.motor.state.busy = true
    empty!(actr.visual.buffer)
    description = "Respond"
    tΔ = .06#rand(Uniform(.050,.070))
    key = "sb" #update later
    register!(actr.scheduler, respond, after, tΔ , actr, task, key;
        description)
    return nothing
end

function clear_motor_buffer(actr)
    empty!(actr.motor.buffer)
    return nothing 
end

function add_to_motor_buffer!(actr, chunk)
    motor = get_buffer(actr, :motor)
    push!(motor, chunk)
    return nothing
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

vo_to_chunk(vo=VisualObject()) = Chunk(;color=vo.color, text=vo.text)

function vo_to_chunk(actr, vo)
    time_created = get_time(actr)
    return Chunk(;time_created, color=vo.color, text=vo.text)
end