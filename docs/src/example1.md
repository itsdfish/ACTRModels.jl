# Example 1

This example will demonstrate how to create memory chunks, add them to the model, perform a memory retrieval, and compute the retrieval time. Declarative memory will consist of two chunks representing two co-workers and their departments: 

```math
\mathbf{c}_1 = \{(\mathrm{name,Bob}),(\mathrm{department,accounting}) \} \\

\mathbf{c}_2 = \{(\mathrm{name,Alice}),(\mathrm{department,HR}) \}
```


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
The first step is to load the required packages. Next, we set a seed for the random number generator. Finally, we can create a vector of chunks using the `Chunk` constructor. Constructor accepts a variable number of keyword arguments as slot-value pairs.
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
After creating the chunks, the next step is to pass them to the constructor `Declarative` to create a declarative memory object. In the next line, we specify a `NamedTuple` of parameters. Finally, the declarative memory object and the parameters are passed to the `ACTR` constructor to generate an ACT-R model object.
```@example examplesetup1
# initialize declarative memory
declarative = Declarative(memory=chunks)

# specify model parameters: partial matching, noise, mismatch penalty, activation noise
Θ = (mmp=true, noise=true, δ=1.0, s=.2)  

# create an ACT-R object with activation noise and partial matching
actr = ACTR(;declarative, Θ...)
```
## Retrieve Chunk 
To retrieve a chunk, pass the ACT-R model objec to the function `retrieve` along with keyword arguments for the retrieval request. `retrieve` will return a vector containing a chunk or an empty vector indicating a retrieval failure.
```@example examplesetup1
# retrieve a chunk associated with accounting
chunk = retrieve(actr; department=:accounting)
```

## Compute Retrieval Time
Retrieval time is computed by passing the ACT-R model object and the retried vector to the function `compute_RT`. If the vector `chunk` is empty, the retrieval failure time will be based on the retrieval threshold, `τ`.
```@example examplesetup1
rt = compute_RT(actr, chunk)
```

# References

Anderson, J. R., Bothell, D., Byrne, M. D., Douglass, S., Lebiere, C., & Qin, Y. (2004). An integrated theory of the mind. Psychological review, 111(4), 1036.