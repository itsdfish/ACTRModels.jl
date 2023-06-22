# Goals and Scope 

The goal of this package is to provide basic functions and types for building models based
on the ACT-R cognitive architecture. There are several approaches for developing ACT-R models. The classic approach involves simulating the internal cognitive processes as a discrete event simulation. A proof-of-concept implementation in Julia can be found in the package [ACTRSimulators.jl](https://github.com/itsdfish/ACTRSimulators.jl). Another approach is to derive a likelihood function to enable maximum likelihood or Bayesian parameter estimation. This approach is limited to mathematically *tractible* ACT-R models, typically of low to moderate complexity. The repo [ACTRTutorials.jl](https://github.com/itsdfish/ACTRTutorials.jl) provides a collection of tutorials for developing ACT-R models within the likelihood approach.

# Installation

In the REPL, type `]` to enter the package model and enter the following:

```julia
add ACTRModels
```

# Quick Example
The example below shows how to create a simple ACT-R model and retrieve a memory using `(animal,rat)` as a retrieval request. 

```@example 
using ACTRModels
using Random

Random.seed!(28194)
# create chunks of declarative knowledge
chunks = [Chunk(;name=:Sigma, animal=:dog),
    Chunk(;name=:Bonkers, animal=:rat)]

# initialize declarative memory
declarative = Declarative(memory=chunks)

# specify model parameters: partial matching, noise, mismatch penalty, activation noise
Θ = (mmp=true, noise=true, δ=1.0, s=0.20, blc=1.5)  

# create an ACT-R object with activation noise and partial matching
actr = ACTR(;declarative, Θ...)

# retrieve a memory chunk
retrieve(actr; animal=:rat)
```
# References

Anderson, J. R., Bothell, D., Byrne, M. D., Douglass, S., Lebiere, C., & Qin, Y. (2004). An integrated theory of the mind. Psychological review, 111(4), 1036.