####################################################################################################
#                                       setup
####################################################################################################
using BenchmarkTools
using ACTRModels
include("utilities.jl")
SUITE = BenchmarkGroup()
####################################################################################################
#                                     retrieval_probs
####################################################################################################
SUITE[:retrieval_probs] = BenchmarkGroup()
n_chunks = [1, 10, 100, 1000]

SUITE[:retrieval_probs][:blc] = BenchmarkGroup()
parms1 = (blc = 1.0, δ = 1.0, γ = 6, mmp = false, sa = false, bll = false, noise = true)
for n ∈ n_chunks
    SUITE[:retrieval_probs][:blc][n] = @benchmarkable(
        retrieval_probs(actr; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms1...))
    )
end

SUITE[:retrieval_probs][:mmp] = BenchmarkGroup()
parms2 = (blc = 1.0, δ = 1.0, γ = 6, mmp = true, sa = false, bll = false, noise = true)
for n ∈ n_chunks
    SUITE[:retrieval_probs][:mmp][n] = @benchmarkable(
        retrieval_probs(actr; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms2...))
    )
end

SUITE[:retrieval_probs][:sa] = BenchmarkGroup()
parms3 = (blc = 1.0, δ = 1.0, γ = 6, mmp = false, sa = true, bll = false, noise = true)
for n ∈ n_chunks
    SUITE[:retrieval_probs][:sa][n] = @benchmarkable(
        retrieval_probs(actr; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms3...))
    )
end

SUITE[:retrieval_probs][:bll] = BenchmarkGroup()
parms4 = (blc = 1.0, δ = 1.0, γ = 6, mmp = false, sa = false, bll = true, noise = true)
for n ∈ n_chunks
    SUITE[:retrieval_probs][:bll][n] = @benchmarkable(
        retrieval_probs(actr, 1.0; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms4...))
    )
end
####################################################################################################
#                                     retrieval
####################################################################################################
SUITE[:retrieve] = BenchmarkGroup()

SUITE[:retrieve][:blc] = BenchmarkGroup()
parms1 = (blc = 1.0, δ = 1.0, γ = 6, mmp = false, sa = false, bll = false, noise = true)
for n ∈ n_chunks
    SUITE[:retrieve][:blc][n] = @benchmarkable(
        retrieve(actr; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms1...))
    )
end

SUITE[:retrieve][:mmp] = BenchmarkGroup()
parms2 = (blc = 1.0, δ = 1.0, γ = 6, mmp = true, sa = false, bll = false, noise = true)
for n ∈ n_chunks
    SUITE[:retrieve][:mmp][n] = @benchmarkable(
        retrieve(actr; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms2...))
    )
end

SUITE[:retrieve][:sa] = BenchmarkGroup()
parms3 = (blc = 1.0, δ = 1.0, γ = 6, mmp = false, sa = true, bll = false, noise = true)
for n ∈ n_chunks
    SUITE[:retrieve][:sa][n] = @benchmarkable(
        retrieve(actr; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms3...))
    )
end

SUITE[:retrieve][:bll] = BenchmarkGroup()
parms4 = (blc = 1.0, δ = 1.0, γ = 6, mmp = false, sa = false, bll = true, noise = true)
for n ∈ n_chunks
    SUITE[:retrieve][:bll][n] = @benchmarkable(
        retrieve(actr, 1.0; slot = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms4...))
    )
end
####################################################################################################
#                                     blend
####################################################################################################
SUITE[:blend] = BenchmarkGroup()
parms1 = (blc = 1.0, δ = 1.0, γ = 6, mmp = false, sa = false, bll = false, noise = true)
blended_slots = [:slot]
for n ∈ n_chunks
    SUITE[:blend][n] = @benchmarkable(
        blend_chunks(actr, blended_slots; s = 1),
        evals = 10,
        samples = 1000,
        setup = (actr = create_model($n; parms1...))
    )
end
