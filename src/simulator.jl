function run!(model::ACTR, task::Task, until=Inf)
    events = s.events
    last_event!(s, until)
    start!(task)
    while is_running(s, until)
        event = dequeue!(events)
        new_time = event.time
        s.time = new_time
        event.fun()
        s.store ? push!(s.complete_events, event) : nothing
        s.trace ? print_event(event) : nothing
    end
    s.trace && !s.running ? print_event(s.time, "", "stopped") : nothing
    return nothing
end