# ACTRModels

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://itsdfish.github.io/ACTRModels.jl/dev/)

The goal of ACTRModels.jl is to provide basic types and functions for developing models based on the [ACT-R](https://en.wikipedia.org/wiki/ACT-R) cognitive architecture. Please see the documentation for installation instructions, working examples, and related pacakges.  


# Simple Example 

```julia 
using ACTRModels

# create chunks of declarative knowledge
chunks = [
    Chunk(; name = :Bob, department = :accounting),
    Chunk(; name = :Alice, department = :HR)
]
# initialize declarative memory
declarative = Declarative(memory = chunks)

# specify model parameters: partial matching, noise, mismatch penalty, activation noise
Θ = (mmp = true, noise = true, δ = 1.0, s = 0.20)

# create an ACT-R object with activation noise and partial matching
actr = ACTR(; declarative, Θ...)

# retrieve a chunk
chunk = retrieve(actr; department = :accounting)
```
