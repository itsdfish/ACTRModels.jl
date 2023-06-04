# Example 1

```@setup examplesetup1
using ACTRModels
using Random
using Plots

Random.seed!(87545)
# create chunks of declarative knowledge
chunks = [Chunk(;name=:Bob, department=:accounting),
    Chunk(;name=:Alice, department=:HR)]

# initialize declarative memory
declarative = Declarative(memory=chunks)

# specify model parameters: partial matching, noise, mismatch penalty, activation noise
Θ = (mmp=true, noise=true, δ=1.0, s=.2)  

# create an ACT-R object with activation noise and partial matching
actr = ACTR(;declarative, Θ...)
```
## Create Chunks

```@example examplesetup1
using ACTRModels
using Random
using Plots

Random.seed!(87545)
# create chunks of declarative knowledge
chunks = [Chunk(;name=:Bob, department=:accounting),
    Chunk(;name=:Alice, department=:HR)]
```

## Create a Model

```@example examplesetup1
# initialize declarative memory
declarative = Declarative(memory=chunks)

# specify model parameters: partial matching, noise, mismatch penalty, activation noise
Θ = (mmp=true, noise=true, δ=1.0, s=.2)  

# create an ACT-R object with activation noise and partial matching
actr = ACTR(;declarative, Θ...)
```
## Retrieve Chunk 

```@example examplesetup1
# retrieve a chunk associated with accounting
chunk = retrieve(actr; department=:accounting)
```

## Compute Retrieval Time

```@example examplesetup1
rt = compute_RT(actr, chunk)
```