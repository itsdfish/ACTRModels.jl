# ACTRModels

The goal of ACTRModels.jl is to provide basic functionality developing likelihood functions for the ACT-R cognitive architecture and generating simulated data. Currently, the library focuses primarily on declarative memory, but functionality can be be extended to other modules. 

## Example
The following example demonstrates how to construct an ACTR object containing declarative memory, retrieve a memory, and compute retrieval time. 

```julia
using ACTRModels, Random

Random.seed!(87545)
# create chunks of declarative knowledge
chunks = [Chunk(;name=:Bob, department=:accounting),
    Chunk(;name=:Alice, department=:HR)]

# initialize declarative memory
memory = Declarative(memory=chunks)

# create an ACT-R object with activation noise and partial matching
s = .2
actr = ACTR(;declarative=memory, mmp=true, δ=1.0, noise=true, s=s)

# retrieve a chunk associated with accounting
chunk = retrieve(actr; department=:accounting)
# generate a reaction time 
rt = compute_RT(actr, chunk)
```

Now that we have generated simulated data it is possible to compute the logpdf using a lognormal race process. 

```julia
# index of retrieved chunk 
chunk_idx = find_index(chunk)
# suppress noise to obtain mean activation
actr.parms.noise = false
# compute activation for each chunk
compute_activation!(actr; department=:accounting)
# get mean activation
μ = get_mean_activations(actr)
# standard deviation 
σ = s * pi / sqrt(3)
# lognormal race distribution object
dist = LNR(;μ=-μ, σ, ϕ=0.0)
# log pdf of retrieval time
logpdf(dist, chunk_idx, rt)
```
