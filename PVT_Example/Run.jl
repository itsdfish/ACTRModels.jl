###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../")
using Revise, DiscreteEventsLite, ACTRModels, Gtk, Cairo
import ACTRModels: start!, press_key!
include("PVT.jl")
include("PVT_Model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = Scheduler(;trace=true)
task = PVT(;scheduler, n_trials=2, visible=true, realtime=true)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
motor = Motor()
actr = ACTR(;scheduler, procedural, visual_location, visual, motor)
conditions = can_attend()
rule1 = Rule(;conditions, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)
conditions = can_wait()
rule2 = Rule(;conditions, action=wait_action, actr, task, name="Wait")
push!(procedural.rules, rule2)
conditions = can_respond()
rule3 = Rule(;conditions, action=respond_action, actr, task, name="Respond")
push!(procedural.rules, rule3)
run!(actr, task)