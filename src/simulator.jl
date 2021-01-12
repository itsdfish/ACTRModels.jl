function run!(actr, task::AbstractTask, until=Inf)
    s = task.scheduler
    last_event!(s, until)
    start!(task, actr)
    start!(actr)
    fire!(actr)
    while is_running(s, until)
        event = dequeue!(s.events)
        s.time = event.time
        event.fun()
        fire!(actr)
        s.store ? push!(s.complete_events, event) : nothing
        s.trace ? print_event(event) : nothing
    end
    s.trace && !s.running ? print_event(s.time, "", "stopped") : nothing
    return nothing
end

function get_time(actr)
    return actr.scheduler.time
end