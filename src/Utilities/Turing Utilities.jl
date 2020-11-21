import Distributions: rand, logpdf, pdf, estimate

function sample_chain(chain)
    parms = (Symbol.(chain.name_map.parameters)...,)
    n = size(chain, 1)*size(chain, 3)
    idx = rand(1:n)
    vals = map(x -> chain[x][idx], parms)
    return NamedTuple{parms}(vals)
end

function posterior_predictive(m, chain, f=x -> x)
    parms = sample_chain(chain)
    return f(m(parms))
end

function posterior_predictive(model, chain, n_samples::Int, f=x -> x)
    return map(x -> posterior_predictive(model, chain, f), 1:n_samples)
end

find_index(actr::ACTR;criteria...) = find_index(actr.declarative.memory;criteria...)

function find_index(chunks::Array{<:Chunk,1}; criteria...)
    for (i,c) in enumerate(chunks)
        match(c;criteria...) ? (return i) : nothing
    end
    return -100
end

find_index(actr::ACTR, funs...; criteria...) = find_index(actr.declarative.memory, funs...; criteria...)

function find_index(chunks::Array{<:Chunk,1}, funs...; criteria...)
    for (i,c) in enumerate(chunks)
        match(c, funs...; criteria...) ? (return i) : nothing
    end
    return -100
end

find_indices(actr::ACTR; criteria...) = find_indices(actr.declarative.memory; criteria...)

function find_indices(chunks::Array{<:Chunk,1}; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end

find_indices(actr::ACTR, funs...; criteria...) = find_indices(actr.declarative.memory, funs...; criteria...)

function find_indices(chunks::Array{<:Chunk,1}, funs...; criteria...)
    idx = Int64[]
    for (i,c) in enumerate(chunks)
        match(c, funs...; criteria...) ? push!(idx, i) : nothing
    end
    return idx
end
