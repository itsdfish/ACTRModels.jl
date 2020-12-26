# ACTRModels

ACTRModels.jl provides basic functionality for ACT-R's declarative memory system. The library can be extended to provide functionaty for other modules.

## Example
The following example demonstrates how to construct an ACTR object containing declarative memory, retrieve a memory, and compute retrieval time. 

```julia
using ACTRModels, Random

Random.seed!(87545)
chunks = [Chunk(;name=:Bob, department=:accounting),
    Chunk(;name=:Alice, department=:HR)]

memory = Declarative(memory=chunks)

actr = ACTR(;declarative=memory, mmp=true, δ=1.0, noise=true, s=.2)

chunk = retrieve(actr; department=:accounting)
rt = compute_RT(actr, chunk)
```
