###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../")
using Revise, DiscreteEventsLite, DataStructures, ACTRModels
import DiscreteEventsLite: run!, last_event!, is_running, print_event
include("PVT.jl")
include("PVT_Model.jl")
include("../src/Procedural_Memory_Functions.jl")
include("../src/simulator.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = Scheduler(;trace=true)
task = PVT(;scheduler)
procedural = Procedural()
visual_location = VisualLocation()
visual = Visual()
motor = Motor()
actr = ACTR(;scheduler, procedural, visual_location, visual, motor)
conditions = can_attend()
rule1 = Rule(;conditions, action=attend_action, actr, task)
push!(procedural.rules, rule1)
conditions = can_wait()
rule2 = Rule(;conditions, action=wait_action, actr, task)
push!(procedural.rules, rule2)
conditions = can_respond()
rule3 = Rule(;conditions, action=respond_action, actr, task)
push!(procedural.rules, rule3)
run!(actr, task, 1.21)