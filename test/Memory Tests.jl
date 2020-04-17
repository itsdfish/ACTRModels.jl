using SafeTestsets

@safetestset "Memory Tests" begin

    @safetestset "baseLevel" begin
        using ACTRModels, Test
        import ACTRModels: baseLevel, baseLevel!
        include("memory.jl")

        lags = [1]
        d = .5
        @test baseLevel(d, lags) == 0

        lags = [1]
        d = .1
        @test baseLevel(d, lags) == 0

        lags = [2,10]
        d = .5
        @test baseLevel(d, lags) ≈ 0.023066 atol=1e-5

        lags = [.5,10]
        d = .4
        @test baseLevel(d, lags) ≈ 0.540936 atol=1e-5
    end

    @safetestset "baseLevel!" begin
        using ACTRModels, Test
        import ACTRModels: baseLevel, baseLevel!
        include("memory.jl")

        actr,memory,chunks = initializeACTR(;bll=true)
        c = getChunk(actr; animal=:dog,name=:Sigma)[1]
        updateLags!(c, 2.0)
        baseLevel!(c, memory)
        @test c.act_bll ≈ -0.346573 atol=1e-5
        c.act_bll = 0.0
        updateLags!(c, 5.0)
        baseLevel!(c, memory)
        @test c.act_bll ≈ -0.80471 atol=1e-5
        c.act_bll = 0.0
        updateRecent!(c, 10.0)
        updateChunk!(c, 12)
        updateLags!(c, 14)
        baseLevel!(c, memory)
        @test c.act_bll ≈ 0.09076 atol=1e-5
        c.act_bll = 0.0
        memory.parms.d = .8
        baseLevel!(c, memory)
        @test c.act_bll ≈ -0.220564 atol=1e-5

        actr,memory,chunks = initializeACTR(; bll=true)
        c = getChunk(actr; animal=:dog, name=:Sigma)[1]
        c.k = 2
        updateChunk!(c, 1)
        updateChunk!(c, 2)
        updateChunk!(c, 4)
        updateLags!(c, 10)
        @test c.N == 4
        @test c.L == 10
        @test all(c.lags .== [6,8])
        @test all(c.recent .== [4,2])
    end

    @safetestset "Chunk" begin
        using ACTRModels, Test
        import ACTRModels: baseLevel, baseLevel!
        include("memory.jl")

        chunk = Chunk(;N=20, animal=:dog, name=:Sigma)
        @test chunk.slots.animal == :dog
        @test chunk.slots.name == :Sigma
        @test chunk.N == 20
    end

    @safetestset "add Chunk" begin
        using ACTRModels, Test
        import ACTRModels: baseLevel, baseLevel!
        include("memory.jl")

        actr,memory,chunks = initializeACTR()
        c = getChunk(actr; animal=:human, name=:Wilford, lastName=:Brimley)
        @test isempty(c)
        addChunk!(actr, 10.0; animal=:human, name=:Wilford, lastName=:Brimley)
        c = getChunk(actr; animal=:human, name=:Wilford, lastName=:Brimley)
        @test !isempty(c)
        @test c[1].N == 1
        addChunk!(actr, 10.0; animal=:human, name=:Wilford, lastName=:Brimley)
        @test c[1].N == 2
    end

    @safetestset "retrievalProb" begin
        using ACTRModels, Test
        import ACTRModels: baseLevel, baseLevel!
        include("memory.jl")
        
        actr,memory,chunks = initializeACTR()
        @test retrievalProb(actr, chunks[2]; animal=:cat, name=:Butters) == (.5,.5)
        @test retrievalProb(actr, chunks[1]; isa=:mammal) == (0,1)

        actr,memory,chunks = initializeACTR(;τ=.5)
        c = getChunk(actr; animal=:rat)
        @test retrievalProb(actr, c; animal=:rat)[1] ≈ 0.38098 atol=1e-5

        actr,memory,chunks = initializeACTR(;τ=.5, mmp=true, δ=1.0)
        c = getChunk(actr; animal=:rat, name=:Joy)
        p1,_ = retrievalProb(actr, c)
        @test p1 ≈ 0.137939 atol=1e-5

        p2,_ = retrievalProb(actr, c; animal=:rat)
        @test p2 ≈ 0.183859 atol=1e-5

        p3,_ = retrievalProb(actr, c; animal=:rat, name=:Joy)
        @test p3 ≈ 0.229243 atol=1e-5

        p3,_ = retrievalProb(actr, c; isa=:rock, animal=:rat, name=:Joy)
        @test p3 == 0

        actr,memory,chunks = initializeACTR(;τ=.5, bll=true)
        c = getChunk(actr; animal=:rat, name=:Joy)
        updateLags!(actr, 1.0)
        p1,_=retrievalProb(actr, c, 1.0)
        updateLags!(actr,3.0)
        p2,_=retrievalProb(actr, c, 3.0)
        memory.parms.d = .8
        p3,_=retrievalProb(actr, c, 3.0)
        @test p1 > p2 > p3

        actr,memory,chunks = initializeACTR(;d=.5, bll=true)
        c = getChunk(actr; animal=:rat, name=:Joy)
        updateRecent!.(c, 5.0)
        updateLags!(actr, 7)
        p1,_=retrievalProb(actr, c, 7.0)
        c[1].N = 2
        p2,_=retrievalProb(actr, c, 7.0)
        c[1].N = 5
        p3,_=retrievalProb(actr, c, 7.0)
        @test p1 < p2 < p3

        actr,memory,chunks = initializeACTR(;sa=true, γ=1.0)
        c = getChunk(actr; animal=:rat, name=:Joy)
        actr.imaginal.chunk = Chunk(;animal=:rat)
        p1,_=retrievalProb(actr, c)
        actr.imaginal.chunk = Chunk(;name=:Joy)
        p2,_=retrievalProb(actr, c)
        @test p2 > p1
    end
end
