###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../")
using Revise, DiscreteEventsLite, DataStructures, ACTRModels, Gtk, Cairo
import DiscreteEventsLite: run!, last_event!, is_running, print_event
include("PVT.jl")
include("PVT_Model.jl")
include("../src/Procedural_Memory_Functions.jl")
include("../src/simulator.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = Scheduler(;trace=true)
task = PVT(;scheduler, n_trials=2, visible=true)
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
@time run!(actr, task)

using CmdStan, Random, Distributions, MCMCChains

model = "
data { 
    // total number of data points in y
    int<lower=1> N;
    // number of groups
    int<lower=1> G;
    // number of predictors
    int<lower=1> P;
    // group index 
    int<lower=1> group[N]; 
    vector[N] y;
    matrix[N,P] X;
} 

parameters {
  real<lower=0> sigma;
  real<lower=0> s;
  real mu_beta0;
  vector[G] beta0;
  vector[P] betas;
}

model {
    real sigma_beta0;
    sigma ~ lognormal(0,1);
    mu_beta0 ~ normal(0, 1);
    s ~ inv_gamma(3, 2);
    sigma_beta0 = sqrt(s);
    beta0 ~ normal(0, sigma_beta0);
    for(i in 1:N){
        y[i] ~ normal(mu_beta0 + beta0[group[i]] + X[i,:]*betas, sigma);
    }
}
"

ProjDir = @__DIR__
# add your path here if not set up on machine's path
set_cmdstan_home!("/home/dfish/cmdstan-2.19.1")
# Generate data.
Random.seed!(10)
N = 10
G = 100
P = 3
X = randn(N*G, P)
z = repeat(1:G, inner=N)
beta = [-2, 0, 2]
intercept = 1
random_intercepts = rand(Normal(0,1), G)
sigma = .1
y = intercept .+ X * beta + random_intercepts[z] + randn(N*G) * sigma

stan_data = Dict("N"=>N*G, "P"=>P, "G"=>G, "X"=>X, "group"=>z, "y"=>y)

config = Sample(; num_samples=1000, num_warmup=1000, adapt=CmdStan.Adapt(;delta=.65))
stanmodel = Stanmodel(config, name="model", model=model, printsummary=false,
    output_format=:mcmcchains, random = CmdStan.Random(25));
    config.algorithm.engine.max_depth = 10
@time rc, samples, cnames = stan(stanmodel, stan_data, ProjDir);
#44




using Turing, ReverseDiff
using Distributions
import Random

Turing.setadbackend(:reversediff)

@model multilevel_with_random_intercept(y, X, z) = begin
  # number of unique groups 
  num_random_intercepts = length(unique(z))

  # number of predictors
  num_predictors = size(X, 2) 

  ### NOTE: Carefully chosen priors should be used for a particular application. ###

  # Prior for standard deviation for errors.
  sigma ~ LogNormal()

  # Prior for coefficients for predictors.
  beta ~ filldist(Normal(), num_predictors)

  # Prior for intercept.
  intercept ~ Normal()

  # Prior for variance of random intercepts. Usually requires thoughtful specification.
  s2 ~ InverseGamma(3, 2)
  s = sqrt(s2)

  # Prior for random intercepts.
  random_intercepts ~ filldist(Normal(0, s), num_random_intercepts)
  
  # likelihood.
  y .~ Normal.(intercept .+ X * beta + random_intercepts[z], sigma)
end

Random.seed!(10) # N=10, G=50: 10: ϵ = 0.003125, 424s #5: ϵ = .05, 306s #15, ϵ = .0125, 230s
# 10 ϵ = .2, 732
N = 10
G = 200
P = 3
X = randn(N*G, P)
z = repeat(1:G, inner=N)
beta = [-2, 0, 2]
intercept = 1
random_intercepts = rand(Normal(0,1), G)
sigma = .1
y = intercept .+ X * beta + random_intercepts[z] + randn(N*G) * sigma

# Sample via NUTS.
@time chain = sample(multilevel_with_random_intercept(y, X, z), NUTS(1000,.65), 2000, progress=true)
