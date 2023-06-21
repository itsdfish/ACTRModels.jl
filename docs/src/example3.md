# Example 3
```@setup examplesetup3
using ACTRModels
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
In this example, we will demonstrate how to use ACT-R's blending mechanism in the context of a decision making. In the decision making task, a person repeatedly chooses between three gambles. The model assumes a person encodes a memory specifying the option and the experienced outcome. 

## Load Packages
First, we will load the required packages.

```@example examplesetup3
using ACTRModels
using Random
using Plots
Random.seed!(87545)
```

## Define Parameters 
Next, we will define the following parameters:

1. `mmp=true`: partial matching enabled
2. `noise=true`: noise added to memory activation
3. `δ=1.0`: mismatch penalty parameter
4. `s=0.20`: logistic scalar for memory activation noise

```@example examplesetup3
Θ = (mmp=true, noise=true, δ=1.0, s=0.20)  
```

## Populate Declarative Memory 
The code below defines six chunks, two chunks for each option. The `option` slot indexes the option and the `value` slot stores the experienced outcome. The parameter `bl` is the base-level constant for a given chunk. We assume that the chunks have different activation for the purpose of illustration. 
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
## Define ACT-R Model 
In the code below, we will create an ACT-R model object by passing the delcarative memory object and parameters to the `ACTR` constructor. 

```@example examplesetup3
# create an ACT-R object with activation noise and partial matching
actr = ACTR(;declarative, Θ...)
```

## Run Simulation
The code below simulates the model $10,000$ times for each option and stores the blended values. 
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
The distribution of blended values for each option is plotted below.
```@example examplesetup3
histogram(blended_values1, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 1", alpha=.75)
histogram!(blended_values2, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 2", alpha=.75)
histogram!(blended_values3, norm=true, xlabel="Blended Values", ylabel="Density", label="Option 3", alpha=.75)
```