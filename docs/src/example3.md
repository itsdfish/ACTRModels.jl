# Example 3
```@setup examplesetup3
using ACTRModels
using SequentialSamplingModels
using Random
using Plots

Random.seed!(87545)
# create chunks of declarative knowledge
chunks = [Chunk(;option=1, value=4.0, bl=1.6),
        Chunk(;option=1, value=2.0, bl=1.5),
        Chunk(;option=2, value=3.5, bl=1.2),
        Chunk(;option=2, value=4.0, bl=1.6),
        Chunk(;option=3, value=2.0, bl=1.0),
        Chunk(;option=3, value=3.0, bl=1.75)]

# initialize declarative memory
declarative = Declarative(memory=chunks)

# specify model parameters: partial matching, noise, mismatch penalty, activation noise
Θ = (mmp=true, noise=true, δ=1.0, s=.2)  

# create an ACT-R object with activation noise and partial matching
actr = ACTR(;declarative, Θ...)

n_sim = 10_000
blended_slots = :value

request = (option=1,)
blended_values1 = map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim)

request = (option=2,)
blended_values2 = map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim)

request = (option=3,)
blended_values3 = map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim)

histogram(blended_values1, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 1", alpha=.70)
histogram!(blended_values2, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 2", alpha=.70)
histogram!(blended_values3, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 3", alpha=.70)
```
The purpose of this example is to develop a likelihood function for retrieval time using an evidence accumulation modeld called Log Normal Race model. 

## Load Packages
The first step is to develop a model and generate simulated data based on Example 1. The code for Example 1 is reproduced below:

```@example examplesetup3
using ACTRModels
using Random
using Plots

Random.seed!(87545)
```

## Define Parameters 

```@example examplesetup3
# specify model parameters: partial matching, noise, mismatch penalty, activation noise
Θ = (mmp=true, noise=true, δ=1.0, s=0.20)  
```

## Populate Declarative Memory 
```@example examplesetup3
# create chunks of declarative knowledge
chunks = [Chunk(;option=1, value = 4.0, bl=1.6),
        Chunk(;option=1, value = 2.0, bl=1.5),
        Chunk(;option=2, value = 3.5, bl=1.2),
        Chunk(;option=2, value = 4.0, bl=1.6),
        Chunk(;option=3, value = 2.0, bl=1.0),
        Chunk(;option=3, value = 3.0, bl=1.75)]
# initialize declarative memory
declarative = Declarative(memory=chunks)
```

```@example examplesetup3
# create an ACT-R object with activation noise and partial matching
actr = ACTR(;declarative, Θ...)
```

## Run Simulation

```@example examplesetup3
n_sim = 10_000
blended_slots = :value

request = (option=1,)
blended_values1 = map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim)

request = (option=2,)
blended_values2 = map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim)

request = (option=3,)
blended_values3 = map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim)
```
## Plot Results

```@example examplesetup3
histogram(blended_values1, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 1", alpha=.75)
histogram!(blended_values2, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 2", alpha=.75)
histogram!(blended_values3, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 3", alpha=.75)
```