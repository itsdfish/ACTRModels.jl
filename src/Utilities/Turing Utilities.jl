import Distributions: rand, logpdf, pdf, estimate

function sampleChain(chain)
    parms = (Symbol.(chain.name_map.parameters)...,)
    idx = rand(1:length(chain))
    vals = map(x -> chain[x][idx], parms)
    return NamedTuple{parms}(vals)
end

function posteriorPredictive(m, chain, f=x -> x)
    parms = sampleChain(chain)
    return f(m(parms))
end

function posteriorPredictive(model, chain, Nsamples::Int, f=x -> x)
    return map(x -> posteriorPredictive(model, chain, f), 1:Nsamples)
end

function reduceData(Data)
    U = unique(Data)
    cnt = map(x -> count(c -> c == x, Data), U)
    newData = NamedTuple[]
    for (u,c) in zip(U, cnt)
        push!(newData, (u...,N = c))
    end
    return newData
end

function logNormParms(μ, σ)
    μ′ = log(μ^2 / sqrt(σ^2 + μ^2))
    σ′ = sqrt(log(1 + σ^2 / (μ^2)))
    return μ′,σ′
end

findIndex(actr::ACTR;criteria...) = findIndex(actr.declarative.memory;criteria...)

function findIndex(chunks::Array{<:Chunk,1}; criteria...)
    for (i,c) in enumerate(chunks)
        Match(c;criteria...) ? (return i) : nothing
    end
    return -100
end

findIndex(actr::ACTR, funs...; criteria...) = findIndex(actr.declarative.memory, funs...; criteria...)

function findIndex(chunks::Array{<:Chunk,1}, funs...; criteria...)
    for (i,c) in enumerate(chunks)
        Match(c, funs...; criteria...) ? (return i) : nothing
    end
    return -100
end

findIndices(actr::ACTR; criteria...) = findIndices(actr.declarative.memory; criteria...)

function findIndices(chunks::Array{<:Chunk,1}; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        Match(c; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

findIndices(actr::ACTR, funs...; criteria...) = findIndices(actr.declarative.memory, funs...; criteria...)

function findIndices(chunks::Array{<:Chunk,1}, funs...; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        Match(c, funs...; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end
