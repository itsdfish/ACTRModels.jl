# Example 2
```@setup examplesetup2
using ACTRModels
using SequentialSamplingModels
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

# retrieve a chunk associated with accounting
chunk = retrieve(actr; department=:accounting)

rt = compute_RT(actr, chunk)

# index of retrieved chunk 
chunk_idx = find_index(chunk)
# compute activation for each chunk
compute_activation!(actr; department=:accounting)
# get mean activation
μ = get_mean_activations(actr)
# standard deviation 
σ = Θ.s * pi / sqrt(3)
# lognormal race distribution object
dist = LNR(;μ=-μ, σ, ϕ=0.0)
# log pdf of retrieval time
logpdf(dist, chunk_idx, rt)
```
The purpose of this example is to develop a likelihood function for retrieval time using an evidence accumulation modeld called Log Normal Race model. 

## Generate Simulated Data
The first step is to develop a model and generate simulated data based on Example 1. The code for Example 1 is reproduced below:

```@example examplesetup2
using ACTRModels
using SequentialSamplingModels
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

# retrieve a chunk associated with accounting
chunk = retrieve(actr; department=:accounting)

# compute retrieval time
rt = compute_RT(actr, chunk)
```

## Compute Log Likelihood

Now that we have simulated data, we can compute the log likelihood of retrieving the chunk after the observed number of seconds. First, we need to identify the chunk index:

### Chunk Index

```@example examplesetup2
# index of retrieved chunk 
chunk_idx = find_index(chunk)
```

### Compute Mean Activation

Next, we will compute activation with the function `compute_activation!` and extract a vector of mean activations for the Log Normal Race. 

```@example examplesetup2
# compute activation for each chunk
compute_activation!(actr; department=:accounting)
# get mean activation
μ = get_mean_activations(actr)
```

### Compute Activation Standard Deviation
The standard deviation for activation is computed as follows
```@example examplesetup2
# standard deviation 
σ = Θ.s * pi / sqrt(3)
```

### Construct Distribution Object
Next, we will create a distribution object for the Log Normal Race model as follows
```@example examplesetup2
# lognormal race distribution object
dist = LNR(;μ=-μ, σ, ϕ=0.0)
```
### Compute Log Likelihood
Finally, we can use `logpdf` to compute the log likelihood of the retrieved chunk:
```@example examplesetup2
# log pdf of retrieval time
logpdf(dist, chunk_idx, rt)
```

### PDF Overlay

One way to verify the likelihood function works is to overlay the PDF on a histogram of simulated data (both based on the same parameters). As expected, the orange line, which represents the PDF, fits the grey histogram well.

```@example examplesetup2
# index for accounting
idx = find_index(actr; department=:accounting)
# generate retrieval times
choices,rts = rand(dist, 10^5)
# extract rts for accounting
acc_rts = rts[choices .== idx]
# probability of retrieving accounting
p_acc = length(acc_rts)/length(rts)
# histogram of retrieval times
hist = histogram(acc_rts, color=:grey, leg=false, grid=false, size=(500,300),
    bins = 100, norm=true, xlabel="Retrieval Time", ylabel="Density")
# weight histogram according to retrieval probability
hist[1][1][:y] *= p_acc
# collection of retrieval time values
x = 0:.01:3
# density for each x value
dens = pdf.(dist, idx, x)
# overlay PDF on histogram
plot!(hist, x, dens, color=:darkorange, linewidth=1.5, xlims=(0,3))
```

# References

Fisher, C. R., Houpt, J. W., & Gunzelmann, G. (2022). Fundamental tools for developing likelihood functions within ACT-R. Journal of Mathematical Psychology, 107, 102636.

Rouder, J. N., Province, J. M., Morey, R. D., Gomez, P., & Heathcote, A. (2015). The lognormal race: A cognitive-process model of choice and latency with desirable psychometric properties. Psychometrika, 80, 491-513.