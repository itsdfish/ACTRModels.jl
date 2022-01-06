using ACTRModels, BenchmarkTools
n = 10
parms = (sa=false, mmp=true, γ=1.3, δ=1.0)
chunks = [Chunk(;s1=j, s2=j) for j in 1:n for k in 1:n]
memory = Declarative(;memory=chunks)
actr = ACTR(;declarative=memory, parms...)
println("Partial Activation n $n")
@btime compute_activation!($actr; s1=1, s2=1);

parms = (sa=true, mmp=true, γ=1.3, δ=1.0)
memory = Declarative(;memory=chunks)
imaginal = Imaginal(;buffer=Chunk(;s1=2,s2=1))
actr = ACTR(;declarative=memory, imaginal=imaginal, parms...)
println("Spreading Activation n $n")
@btime compute_activation!($actr; s1=1, s2=1);

parms = (noise=true,)
memory = Declarative(;memory=chunks)
actr = ACTR(;declarative=memory, parms...)
println("Activation Noise n $n")
@btime compute_activation!($actr);

n = 100
parms = (sa=false, mmp=true, γ=1.3, δ=1.0)
chunks = [Chunk(;s1=j, s2=j) for j in 1:n for k in 1:n]
memory = Declarative(;memory=chunks)
actr = ACTR(;declarative=memory, parms...)
println("Partial Activation n $n")
@btime compute_activation!($actr; s1=1, s2=1);

parms = (sa=true, mmp=true, γ=1.3, δ=1.0)
memory = Declarative(;memory=chunks)
imaginal = Imaginal(;buffer=Chunk(;s1=2,s2=1))
actr = ACTR(;declarative=memory, imaginal=imaginal, parms...)
println("Spreading Activation n $n")
@btime compute_activation!($actr; s1=1, s2=1);

parms = (noise=true,)
memory = Declarative(;memory=chunks)
actr = ACTR(;declarative=memory, parms...)
println("Activation Noise n $n")
@btime compute_activation!($actr);

n = 10
parms = (sa=false, mmp=true, γ=1.3, δ=1.0)
chunks = [Chunk(;s1=j, s2=j) for j in 1:n for k in 1:n]
memory = Declarative(;memory=chunks)
actr = ACTR(;declarative=memory, parms...)
println("Partial Activation n $n")
@btime retrieval_probs($actr; s1=1, s2=1);

parms = (sa=true, mmp=true, γ=1.3, δ=1.0)
memory = Declarative(;memory=chunks)
imaginal = Imaginal(;buffer=Chunk(;s1=2,s2=1))
actr = ACTR(;declarative=memory, imaginal=imaginal, parms...)
println("Spreading Activation n $n")
@btime retrieval_probs($actr; s1=1, s2=1);

n = 100
parms = (sa=false, mmp=true, γ=1.3, δ=1.0)
chunks = [Chunk(;s1=j, s2=j) for j in 1:n for k in 1:n]
memory = Declarative(;memory=chunks)
actr = ACTR(;declarative=memory, parms...)
println("Partial Activation n $n")
@btime retrieval_probs($actr; s1=1, s2=1);

parms = (sa=true, mmp=true, γ=1.3, δ=1.0)
memory = Declarative(;memory=chunks)
imaginal = Imaginal(;buffer=Chunk(;s1=2,s2=1))
actr = ACTR(;declarative=memory, imaginal=imaginal, parms...)
println("Spreading Activation n $n")
@btime retrieval_probs($actr; s1=1, s2=1);