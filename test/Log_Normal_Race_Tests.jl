using SafeTestsets

@safetestset "LogNormal Race Tests" begin
    using ACTRModels, Test, Distributions, Random
    Random.seed!(54054)
    d1 = LNR(;μ=[1.0], σ=1.0, ϕ=.1)
    v1 = .3
    p1 = pdf(d1, 1, v1)
    p2 = pdf(LogNormal(1, 1), v1-.1)
    @test p1 ≈ p2
    d2 = LNR(;μ=[1.0,0.0],σ=1.0,ϕ=.1)
    d3 = LNR(;μ=[1.0,0.0,0.0], σ=1.0, ϕ=.1)
    p1 = pdf(d2, 1, v1)
    p2 = pdf(d3, 1 ,v1)
    @test p1 > p2
    @test p1 ≈ pdf(LogNormal(1, 1), v1-.1)*(1-cdf(LogNormal(0, 1), v1-.1))

    m1,m2=-2,-1
    σ = .9
    ϕ = 0.0
    d = LNR(μ=[m1,m2], σ=σ, ϕ=ϕ)
    data = rand(d, 10^4)
    x = -3:.01:3
    y = map(x->sum(logpdf.(LNR(μ=[x,m2], σ=σ, ϕ=ϕ), data)), x)
    mv,mi = findmax(y)
    @test m1 ≈ x[mi] atol = .05

    y = map(x->sum(logpdf.(LNR(μ=[m1,x], σ=σ, ϕ=ϕ), data)), x)
    mv,mi = findmax(y)
    @test m2 ≈ x[mi] atol = .05

    y1 = map(x->sum(logpdf.(LNR(μ=[m1,x], σ=σ, ϕ=ϕ), data)), x)
    y2 = map(x->sum(log.(pdf.(LNR(μ=[m1,x], σ=σ, ϕ=ϕ), data))), x)
    @test y1 ≈ y2 atol = .00001
end
