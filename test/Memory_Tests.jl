using SafeTestsets

@safetestset "Memory Tests" begin
    @safetestset "baselevel" begin
        using ACTRModels, Test
        import ACTRModels: baselevel, baselevel!
        include("memory.jl")

        lags = [1]
        d = 0.5
        @test baselevel(d, lags) == 0

        lags = [1]
        d = 0.1
        @test baselevel(d, lags) == 0

        lags = [2, 10]
        d = 0.5
        @test baselevel(d, lags) ≈ 0.023066 atol = 1e-5

        lags = [0.5, 10]
        d = 0.4
        @test baselevel(d, lags) ≈ 0.540936 atol = 1e-5
    end

    @safetestset "baselevel!" begin
        using ACTRModels, Test
        import ACTRModels: baselevel, baselevel!
        include("memory.jl")

        actr, memory, chunks = initializeACTR(; bll = true)
        c = get_chunks(actr; animal = :dog, name = :Sigma)[1]
        update_lags!(c, 2.0)
        baselevel!(actr, c)
        @test c.act_bll ≈ -0.346573 atol = 1e-5
        c.act_bll = 0.0
        update_lags!(c, 5.0)
        baselevel!(actr, c)
        @test c.act_bll ≈ -0.80471 atol = 1e-5
        c.act_bll = 0.0
        update_recent!(c, 10.0)
        update_chunk!(c, 12)
        update_lags!(c, 14)
        baselevel!(actr, c)
        @test c.act_bll ≈ 0.09076 atol = 1e-5
        c.act_bll = 0.0
        actr.parms.d = 0.8
        baselevel!(actr, c)
        @test c.act_bll ≈ -0.220564 atol = 1e-5

        actr, memory, chunks = initializeACTR(; bll = true)
        c = get_chunks(actr; animal = :dog, name = :Sigma)[1]
        c.k = 2
        update_chunk!(c, 1)
        update_chunk!(c, 2)
        update_chunk!(c, 4)
        update_lags!(c, 10)
        @test c.N == 4
        @test c.L == 10
        @test all(c.lags .== [6, 8])
        @test all(c.recent .== [4, 2])
    end

    @safetestset "Chunk" begin
        using ACTRModels, Test
        import ACTRModels: baselevel, baselevel!
        include("memory.jl")

        chunk = Chunk(; N = 20, animal = :dog, name = :Sigma)
        @test chunk.slots.animal == :dog
        @test chunk.slots.name == :Sigma
        @test chunk.N == 20
    end

    @safetestset "add Chunk" begin
        using ACTRModels, Test
        import ACTRModels: baselevel, baselevel!
        include("memory.jl")

        actr, memory, chunks = initializeACTR()
        c = get_chunks(actr; animal = :human, name = :Wilford, last_name = :Brimley)
        @test isempty(c)
        add_chunk!(actr, 10.0; animal = :human, name = :Wilford, last_name = :Brimley)
        c = get_chunks(actr; animal = :human, name = :Wilford, last_name = :Brimley)
        @test !isempty(c)
        @test c[1].N == 1
        @test c[1].time_created == 10.0
        @test c[1].recent[1] == 10.0

        add_chunk!(actr, 20.0; animal = :human, name = :Wilford, last_name = :Brimley)
        @test c[1].N == 2
        @test c[1].time_created == 10.0
        @test c[1].recent[1] == 20.0
    end

    @safetestset "retrieval_prob" begin
        using ACTRModels, Test
        import ACTRModels: baselevel, baselevel!
        include("memory.jl")

        actr, memory, chunks = initializeACTR()
        @test retrieval_prob(actr, chunks[2]; animal = :cat, name = :Butters) == (0.5, 0.5)
        @test retrieval_prob(actr, chunks[1]; isa = :mammal) == (0, 1)

        actr, memory, chunks = initializeACTR(; τ = 0.5)
        c = get_chunks(actr; animal = :rat)
        @test retrieval_prob(actr, c; animal = :rat)[1] ≈ 0.38098 atol = 1e-5

        actr, memory, chunks = initializeACTR(; τ = 0.5, mmp = true, δ = 1.0)
        c = get_chunks(actr; animal = :rat, name = :Joy)
        p1, _ = retrieval_prob(actr, c)
        @test p1 ≈ 0.137939 atol = 1e-5

        p2, _ = retrieval_prob(actr, c; animal = :rat)
        @test p2 ≈ 0.183859 atol = 1e-5

        p3, _ = retrieval_prob(actr, c; animal = :rat, name = :Joy)
        @test p3 ≈ 0.229243 atol = 1e-5

        p3, _ = retrieval_prob(actr, c; isa = :rock, animal = :rat, name = :Joy)
        @test p3 == 0

        actr, memory, chunks = initializeACTR(; τ = 0.5, bll = true)
        c = get_chunks(actr; animal = :rat, name = :Joy)
        update_lags!(actr, 1.0)
        p1, _ = retrieval_prob(actr, c, 1.0)
        update_lags!(actr, 3.0)
        p2, _ = retrieval_prob(actr, c, 3.0)
        actr.parms.d = 0.8
        p3, _ = retrieval_prob(actr, c, 3.0)
        @test p1 > p2 > p3

        actr, memory, chunks = initializeACTR(; d = 0.5, bll = true)
        c = get_chunks(actr; animal = :rat, name = :Joy)
        update_recent!.(c, 5.0)
        update_lags!(actr, 7)
        p1, _ = retrieval_prob(actr, c, 7.0)
        c[1].N = 2
        p2, _ = retrieval_prob(actr, c, 7.0)
        c[1].N = 5
        p3, _ = retrieval_prob(actr, c, 7.0)
        @test p1 < p2 < p3

        actr, memory, chunks = initializeACTR(; sa = true, γ = 1.0)
        c = get_chunks(actr; animal = :rat, name = :Joy)
        actr.imaginal.buffer[1] = Chunk(; animal = :rat)
        p1, _ = retrieval_prob(actr, c)
        actr.imaginal.buffer[1] = Chunk(; name = :Joy)
        p2, _ = retrieval_prob(actr, c)
        @test p2 > p1
    end

    @safetestset "modify!" begin
        using ACTRModels, Test
        chunks = Chunk[
            Chunk(; isa = :bafoon, animal = :dog, name = :Sigma, retrieved = [false]),
            Chunk(; isa = :mammal, animal = :cat, name = :Butters, retrieved = [false])
        ]
        memory = Declarative(; memory = chunks)
        actr = ACTR(; declarative = memory)
        modify!(chunks[2].slots, retrieved = true)
        @test chunks[2].slots.retrieved[1] == true
    end

    @safetestset "filter" begin
        using ACTRModels, Test
        chunks = Chunk[
            Chunk(; isa = :bafoon, animal = :dog, name = :Sigma, retrieved = [false]),
            Chunk(; isa = :mammal, animal = :cat, name = :Butters, retrieved = [false])
        ]
        memory = Declarative(; memory = chunks)
        actr = ACTR(; declarative = memory, mmp = true)
        request = retrieval_request(actr; isa = :mammal)
        @test request[1].slots.name == :Butters
    end

    @safetestset "count_values" begin
        using ACTRModels, Test
        import ACTRModels: count_values
        chunk = Chunk(a = :a, b = :a, c = :v)
        @test count_values(chunk, :a) == 2
        @test count_values(chunk, :v) == 1
        @test count_values(chunk, :c) == 0
    end

    @safetestset "update_recent!" begin
        using ACTRModels, Test
        chunk = Chunk(a = :a, b = :a, c = :v)
        update_recent!(chunk, 0.10)
        @test chunk.recent[1] == 0.1
        update_recent!(chunk, 0.20)
        @test chunk.recent[1] == 0.2
        @test length(chunk.recent) == 1
        chunk.k = 2
        update_recent!(chunk, 0.10)
        update_recent!(chunk, 0.20)
        update_recent!(chunk, 0.30)
        @test chunk.recent[1] == 0.3
        @test chunk.recent[2] == 0.2
        @test length(chunk.recent) == 2
    end

    @safetestset "update_lags!" begin
        using ACTRModels, Test
        chunk = Chunk(a = :a, b = :a, c = :v, k = 2)
        update_recent!(chunk, 0.10)
        update_recent!(chunk, 0.20)
        update_lags!(chunk, 1.0)
        @test chunk.lags[1] == 1 - 0.2
        @test chunk.lags[2] == 1 - 0.1
    end

    @safetestset "update_chunk!" begin
        using ACTRModels, Test
        chunk = Chunk(a = :a, b = :a, c = :v)
        update_chunk!(chunk, 0.10)
        @test chunk.recent[1] == 0.1
        @test chunk.N == 2
        update_chunk!(chunk, 0.20)
        @test chunk.recent[1] == 0.2
        @test chunk.N == 3
        @test length(chunk.recent) == 1
    end

    @safetestset "spreading activation" begin
        using ACTRModels, Test
        chunks = [Chunk(a = :a, b = :b, c = :c), Chunk(a = :a, b = :b, c = :a)]
        memory = Declarative(memory = chunks)
        imaginal = Imaginal(buffer = Chunk(a = :a, b = :b))
        actr = ACTR(declarative = memory, imaginal = imaginal, γ = 1.6)
        compute_activation!(actr)
        @test chunks[1].act == 0.0
        @test chunks[2].act == 0.0
        actr.parms.sa = true
        compute_activation!(actr)
        @test chunks[1].act ≈ 0.3575467 atol = 1e-5
        @test chunks[2].act ≈ 0.7041203 atol = 1e-5
    end

    @safetestset "spreading activation zero" begin
        using ACTRModels, Test
        chunks = [
            Chunk(; isa = :mammal, animal = :dog, name = :Sigma),
            Chunk(; isa = :mammal, animal = :cat, name = :Butters)
        ]
        memory = Declarative(; memory = chunks)
        actr = ACTR(; declarative = memory, sa = true, γ = 1.0)
        p, _ = retrieval_probs(actr)
        sa = map(x -> x.act_sa, chunks)
        @test sa[1] ≈ 0.0 atol = 1e-10
        @test sa[2] ≈ 0.0 atol = 1e-10

        memory = Declarative(; memory = chunks)
        T = typeof(chunks)
        imaginal = Imaginal(buffer = T)
        empty!(imaginal.buffer)
        actr = ACTR(; declarative = memory, imaginal = imaginal, sa = true, γ = 1.0)
        p, _ = retrieval_probs(actr)
        sa = map(x -> x.act_sa, chunks)
        @test sa[1] ≈ 0.0 atol = 1e-10
        @test sa[2] ≈ 0.0 atol = 1e-10

        chunk = Chunk(; isa = :mammal, animal = :cat, name = :Butters)
        push!(imaginal.buffer, chunk)
        p, _ = retrieval_probs(actr)
        sa = map(x -> x.act_sa, chunks)
        @test sa[1] != 0.0
        @test sa[2] != 0.0

        empty!(imaginal.buffer)
        p, _ = retrieval_probs(actr)
        sa = map(x -> x.act_sa, chunks)
        @test sa[1] ≈ 0.0 atol = 1e-10
        @test sa[2] ≈ 0.0 atol = 1e-10

        chunk = Chunk(; isa = :arachnid, animal = :spider, name = :Soen)
        push!(imaginal.buffer, chunk)
        p, _ = retrieval_probs(actr)
        sa = map(x -> x.act_sa, chunks)
        @test sa[1] ≈ 0.0 atol = 1e-10
        @test sa[2] ≈ 0.0 atol = 1e-10
    end

    @safetestset "partial matching" begin
        using ACTRModels, Test
        chunk = Chunk(a = :a, b = :b)
        memory = Declarative(memory = [chunk])
        actr = ACTR(declarative = memory, mmp = true, δ = 1.0)
        compute_activation!(actr)
        @test chunk.act == 0.0
        compute_activation!(actr; a = :a)
        @test chunk.act == 0.0
        compute_activation!(actr; a = :a, b = :b)
        @test chunk.act == 0.0
        compute_activation!(actr; a = :b, b = :b)
        @test chunk.act == -1.0
        compute_activation!(actr; a = :a, b = :a)
        @test chunk.act == -1.0
        compute_activation!(actr; a = :c, b = :c)
        @test chunk.act == -2.0
    end

    @safetestset "get_chunks" begin
        using ACTRModels, Test
        chunks = [Chunk(a = :a, b = :c), Chunk(a = :a, b = :b)]
        memory = Declarative(memory = chunks)
        actr = ACTR(declarative = memory)
        result = get_chunks(actr; a = :b)
        @test isempty(result)

        result = get_chunks(actr; a = :a)
        @test !isempty(result)
        @test length(result) == 2
        @test result[1].slots.a == :a
        @test result[1].slots.b == :c
        @test result[2].slots.a == :a
        @test result[2].slots.b == :b

        result = get_chunks(actr; a = :a, b = :b)
        @test !isempty(result)
        @test length(result) == 1
        @test result[1].slots.a == :a
        @test result[1].slots.b == :b
    end

    @safetestset "first_chunk" begin
        using ACTRModels, Test
        chunks = [Chunk(a = :a, b = :c), Chunk(a = :a, b = :b)]
        memory = Declarative(memory = chunks)
        actr = ACTR(declarative = memory)
        result = get_chunks(actr; a = :b)
        @test isempty(result)

        result = first_chunk(actr; a = :a)
        @test !isempty(result)
        @test length(result) == 1
        @test result[1].slots.a == :a
        @test result[1].slots.b == :c
    end

    @safetestset "reset_activation!" begin
        using ACTRModels, Test
        import ACTRModels: reset_activation!
        chunks = [Chunk(a = :a, b = :b, c = :c), Chunk(a = :a, b = :b, c = :a)]
        chunk = chunks[1]
        memory = Declarative(memory = chunks)
        imaginal = Imaginal(buffer = Chunk(a = :a, b = :b))
        actr = ACTR(
            declarative = memory,
            imaginal = imaginal,
            mmp = true,
            noise = true,
            bll = true,
            sa = true,
            γ = 1.6,
            δ = 1.0
        )
        compute_activation!(actr, 3.0; a = :b)
        @test chunk.act_bll != 0
        @test chunk.act_pm != 0
        @test chunk.act_sa != 0
        @test chunk.act_noise != 0
        reset_activation!(chunk)
        @test chunk.act_bll == 0
        @test chunk.act_pm == 0
        @test chunk.act_sa == 0
        @test chunk.act_noise == 0
    end

    @safetestset "total_activation!" begin
        using ACTRModels, Test
        import ACTRModels: total_activation!
        chunk = Chunk()
        chunk.act_blc = 0.5
        chunk.act_bll = 1.0
        chunk.act_pm = 1.0
        chunk.act_sa = 1.0
        chunk.act_noise = 1.0
        total_activation!(chunk)
        @test chunk.act ≈ 2.5 atol = 1e-5
    end

    @safetestset "get_parm" begin
        using ACTRModels, Test
        chunks = [Chunk(a = :a, b = :b, c = :c), Chunk(a = :a, b = :b, c = :a)]
        chunk = chunks[1]
        memory = Declarative(memory = chunks)
        actr = ACTR(
            declarative = memory,
            mmp = true,
            noise = true,
            bll = true,
            sa = true,
            γ = 1.6,
            δ = 1.0,
            Σ = 0.3
        )
        @test get_parm(actr, :δ) ≈ 1.0 atol = 1e-5
        @test get_parm(actr, :Σ) ≈ 0.3 atol = 1e-5
        @test get_parm(actr, :noise)
    end

    @safetestset "compute_RT" begin
        using ACTRModels, Test, Distributions, Random
        Random.seed!(41140)
        chunks = [Chunk(a = :a, b = :b, c = :c), Chunk(a = :a, b = :b, c = :a)]
        chunk = chunks[1]
        memory = Declarative(memory = chunks)
        actr = ACTR(declarative = memory, blc = 1.5)
        retrieved = retrieve(actr; a = :a, b = :b, c = :c)
        rt = compute_RT(actr, retrieved)
        @test rt ≈ exp(-1.5) atol = 1e-5

        retrieved = retrieve(actr; a = :z)
        rt = compute_RT(actr, retrieved)
        @test rt ≈ exp(0.0) atol = 1e-5

        chunks = [Chunk(a = :a, b = :b, c = :c), Chunk(a = :a, b = :b, c = :a)]
        chunk = chunks[1]
        s = 0.2
        memory = Declarative(memory = chunks)
        actr = ACTR(declarative = memory, blc = 1.5, noise = true, s = s)
        retrieved = retrieve(actr; a = :a, b = :b, c = :c)
        function sim(actr, chunk)
            compute_activation!(actr, chunk)
            return compute_RT(actr, retrieved)
        end
        σ = s * pi / sqrt(3)
        rts = map(_ -> sim(actr, retrieved), 1:20_000)
        @test mean(rts) ≈ mean(LogNormal(-1.5, σ)) atol = 1e-3
        @test std(rts) ≈ std(LogNormal(-1.5, σ)) atol = 1e-3
    end

    @safetestset "match" begin
        using ACTRModels, Test
        chunk = Chunk(a = :a, b = :b, c = :c)
        @test match(chunk, a = :a)
        @test !match(chunk, a = :b)
        @test !match(chunk, d = :b)
        @test match(chunk,!=,==,a = :b,b = :b)
        @test !match(chunk,!=,==,a = :a,b = :b)

        @test match(chunk, a = :a; check_value = false)
        @test match(chunk, a = :b; check_value = false)
        @test !match(chunk, d = :a; check_value = false)
    end

    @safetestset "Threshold" begin
        using ACTRModels, Test, Distributions, Random
        Random.seed!(41140)
        chunks = [
            Chunk(a = :a, b = :b, c = :c, bl = -1.0),
            Chunk(a = :a, b = :b, c = :a, bl = -1.0)
        ]
        memory = Declarative(memory = chunks)
        τ = 0.0
        actr = ACTR(; declarative = memory, τ, noise = false)
        retrieved = retrieve(actr; a = :a)
        @test isempty(retrieved)
        @test actr.parms.τ′ == τ

        τ = -2.0
        actr = ACTR(; declarative = memory, τ, noise = false)
        retrieved = retrieve(actr; a = :a)
        @test !isempty(retrieved)
        @test actr.parms.τ′ == τ

        τ = -20.0
        actr = ACTR(; declarative = memory, τ, noise = true)
        retrieved = retrieve(actr; a = :a)
        @test !isempty(retrieved)
        @test actr.parms.τ′ != τ
    end

    @safetestset "base level learning example" begin
        using ACTRModels, Test, Distributions, Random
        memory = Declarative(memory = Chunk[])
        bll = true
        d = 0.5
        noise = false
        actr = ACTR(; declarative = memory, bll, d, noise)
        cur_time = 45.185
        for _ = 1:10
            add_chunk!(actr, cur_time; a = :a)
            cur_time += rand(Uniform(0, 100))
        end
        cur_time = 1265.185
        add_chunk!(actr, cur_time; a = :a)
        cur_time = 1590.185
        compute_activation!(actr, cur_time)
        chunk = actr.declarative.memory[1]
        @test chunk.act_bll ≈ -0.905594 rtol = 0.0001
        # based on lisp act-r example:
        # 1590.185   DECLARATIVE            START-RETRIEVAL 
        # Computing base-level from 11 references (1265.185)
        #   creation time: 45.185 decay: 0.5  Optimized-learning: 1
        # base-level value: -0.905594
    end

    @safetestset "blend_chunks" begin
        using ACTRModels, Test, Random, Distributions
        Random.seed!(598)
        chunks = [Chunk(; a = 1, b = 0), Chunk(; a = 1, b = 3)]
        parms = (mmp = true, δ = 1.0, noise = true, s = 0.2)
        declarative = Declarative(; memory = chunks)
        actr = ACTR(; declarative, parms...)

        request = (a = 2,)
        blended_slots = :b
        n_sim = 10_000
        mean_value1 =
            map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim) |> mean
        @test mean_value1 ≈ 1.5 atol = 0.01

        chunks = [Chunk(; a = 1, b = 0), Chunk(; a = 2, b = 3)]
        parms = (mmp = true, δ = 1.0, noise = true, s = 0.2)
        declarative = Declarative(; memory = chunks)
        actr = ACTR(; declarative, parms...)
        request = (a = 2,)
        blended_slots = :b
        n_sim = 10_000
        mean_value2 =
            map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim) |> mean
        @test mean_value1 < mean_value2

        chunks = [Chunk(; a = 2, b = 0), Chunk(; a = 1, b = 3)]
        parms = (mmp = true, δ = 1.0, noise = true, s = 0.2)
        declarative = Declarative(; memory = chunks)
        actr = ACTR(; declarative, parms...)
        request = (a = 2,)
        blended_slots = :b
        n_sim = 10_000
        mean_value3 =
            map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim) |> mean
        @test mean_value1 > mean_value3

        chunks = [Chunk(; a = 2, b = 0), Chunk(; a = 1, b = 3)]
        parms = (mmp = true, δ = 0.5, noise = true, s = 0.2)
        declarative = Declarative(; memory = chunks)
        actr = ACTR(; declarative, parms...)
        request = (a = 2,)
        blended_slots = :b
        n_sim = 10_000
        mean_value4 =
            map(_ -> blend_chunks(actr, blended_slots; request...), 1:n_sim) |> mean
        @test mean_value4 > mean_value3
    end

    @safetestset "blend_slots numeric" begin
        using ACTRModels, Test, Random
        import ACTRModels: blend_slots
        Random.seed!(598)
        chunks = [Chunk(; a = 1, b = 0), Chunk(; a = 1, b = 3)]
        parms = (mmp = true, δ = 1.0, noise = true, s = 0.2)
        declarative = Declarative(; memory = chunks)
        actr = ACTR(; declarative, parms...)

        blended_slots = :b
        probs = [0.3, 0.7]
        v = blend_slots(actr, chunks, probs, blended_slots)
        @test v ≈ 2.1 atol = 1e-4
    end

    @safetestset "blend_slots non-numeric" begin
        using ACTRModels, Test, Random
        import ACTRModels: blend_slots

        function dissim_func(s, x, y, f)
            if (f(x, :a1) && f(y, :a2)) || (f(y, :a1) && f(x, :a2))
                return 0.1
            elseif (f(x, :a1) && f(y, :a3)) || (f(y, :a1) && f(x, :a3))
                return 0.2
            elseif (f(x, :a2) && f(y, :a3)) || (f(y, :a2) && f(x, :a3))
                return 0.1
            end
            return !f(x, y) ? 1.0 : 0.0
        end

        chunks = [
            Chunk(; a = :a1, b = :b1, v = 0.3, bl = 1.0),
            Chunk(; a = :a1, b = :b1, v = 0.2, bl = 1.0),
            Chunk(; a = :a2, b = :b2, v = 0.2, bl = 1.5),
            Chunk(; a = :a3, b = :b3, v = 0.1, bl = 0.5)
        ]

        declarative = Declarative(memory = chunks)

        parms = (noise = true, s = 0.20, mmp = true, τ = -10.0)

        actr = ACTR(; declarative, dissim_func, parms...)

        blended_slots = :a
        request = (b = :b1,)
        funs = (==,)

        probs = [0.40, 0.35, 0.15, 0.10]
        values = map(c -> c.slots[blended_slots], chunks)

        blended_value = blend_slots(actr, probs, values, blended_slots)

        @test blended_value == :a1

        probs = [0.30, 0.05, 0.55, 0.10]
        values = map(c -> c.slots[blended_slots], chunks)

        blended_value = blend_slots(actr, probs, values, blended_slots)

        @test blended_value == :a2
    end

    @safetestset "custom dissim_func" begin
        using ACTRModels
        using Test

        function dissim_func(s, x, y, f)
            if (f(x, :a1) && f(y, :a2)) || (f(y, :a1) && f(x, :a2))
                return 0.1
            elseif (f(x, :a1) && f(y, :a3)) || (f(y, :a1) && f(x, :a3))
                return 0.2
            elseif (f(x, :a2) && f(y, :a3)) || (f(y, :a2) && f(x, :a3))
                return 0.1
            end
            return !f(x, y) ? 1.0 : 0.0
        end

        chunks = [
            Chunk(; a = :a1, b = :b1, v = 0.3, bl = 1.0),
            Chunk(; a = :a2, b = :b2, v = 0.2, bl = 1.5),
            Chunk(; a = :a3, b = :b3, v = 0.1, bl = 0.5)
        ]

        declarative = Declarative(memory = chunks)

        parms = (noise = true, s = 0.20, mmp = true, τ = -10.0, δ = 2.0)

        actr = ACTR(; declarative, dissim_func, parms...)

        retrieve(actr; a = :a1)
        @test chunks[1].act_pm ≈ 0.00
        @test chunks[2].act_pm ≈ 0.20
        @test chunks[3].act_pm ≈ 0.40

        retrieve(actr; a = :a2)
        @test chunks[1].act_pm ≈ 0.20
        @test chunks[2].act_pm ≈ 0.00
        @test chunks[3].act_pm ≈ 0.20

        retrieve(actr)
        @test chunks[1].act_pm ≈ 0.00
        @test chunks[2].act_pm ≈ 0.00
        @test chunks[3].act_pm ≈ 0.00

        requested = retrieve(actr; zz = 1.0)
        @test isempty(requested)
    end

    @safetestset "default dissim_func" begin
        using ACTRModels
        using Test

        chunks = [
            Chunk(; a = :a1, b = :b1, v = 0.3, bl = 1.0),
            Chunk(; a = :a2, b = :b2, v = 0.2, bl = 1.5),
            Chunk(; a = :a3, b = :b3, v = 0.1, bl = 0.5)
        ]

        declarative = Declarative(memory = chunks)

        parms = (noise = true, s = 0.20, mmp = true, τ = -10.0, δ = 2.0)

        actr = ACTR(; declarative, parms...)

        retrieve(actr; a = :a1)
        @test chunks[1].act_pm ≈ 0.00
        @test chunks[2].act_pm ≈ 2.00
        @test chunks[3].act_pm ≈ 2.00

        retrieve(actr; a = :a2)
        @test chunks[1].act_pm ≈ 2.00
        @test chunks[2].act_pm ≈ 0.00
        @test chunks[3].act_pm ≈ 2.00

        retrieve(actr)
        @test chunks[1].act_pm ≈ 0.00
        @test chunks[2].act_pm ≈ 0.00
        @test chunks[3].act_pm ≈ 0.00
    end

    @safetestset "get_chunks_exact" begin
        using ACTRModels, Test
        using ACTRModels: get_chunks_exact
        chunks = [Chunk(; a = 1, b = 0)]
        declarative = Declarative(; memory = chunks)

        result = get_chunks_exact(declarative; a = 1, b = 0)
        @test !isempty(result)

        result = get_chunks_exact(declarative; a = 1, b = 3)
        @test isempty(result)

        result = get_chunks_exact(declarative; a = 1)
        @test isempty(result)
    end

    @safetestset "negation" begin
        @safetestset "with negation" begin
            using ACTRModels
            using Test

            chunks = [
                Chunk(; a = 1, b = 2),
                Chunk(; a = 2, b = 2),
                Chunk(; a = 3, b = 2)
            ]

            parms = (
                mmp = true,
                δ = 1,
                noise = false,
                τ = -10
            )

            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            chunk = retrieve(actr; funs = (≠,), a = 1)

            @test chunks[1].act_mean ≈ -1
            @test chunks[2].act_mean ≈ 0
            @test chunks[3].act_mean ≈ 0
        end

        @safetestset "no negation" begin
            using ACTRModels
            using Test

            chunks = [
                Chunk(; a = 1, b = 2),
                Chunk(; a = 2, b = 2),
                Chunk(; a = 3, b = 2)
            ]

            parms = (
                mmp = true,
                δ = 1,
                noise = false,
                τ = -10
            )

            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            chunk = retrieve(actr; a = 1)

            @test chunks[1].act_mean ≈ 0
            @test chunks[2].act_mean ≈ -1
            @test chunks[3].act_mean ≈ -1
        end

        @safetestset "no negation requested" begin
            using ACTRModels
            using Test

            chunks = [
                Chunk(; a = 1, b = 2),
                Chunk(; a = 2, b = 2),
                Chunk(; a = 3, b = 2)
            ]

            parms = (
                mmp = true,
                δ = 1,
                noise = false,
                τ = -10
            )

            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            requested = retrieval_request(actr; a = 1)

            @test length(requested) == 3
        end

        @safetestset "negation requested" begin
            using ACTRModels
            using Test

            chunks = [
                Chunk(; a = 1, b = 2),
                Chunk(; a = 2, b = 2),
                Chunk(; a = 3, b = 2)
            ]

            parms = (
                mmp = true,
                δ = 1,
                noise = false,
                τ = -10
            )

            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            requested = retrieval_request(actr; funs = (≠,), a = 1)

            @test length(requested) == 3
        end

        @safetestset "no negation requested mmp false" begin
            using ACTRModels
            using Test

            chunks = [
                Chunk(; a = 1, b = 2),
                Chunk(; a = 2, b = 2),
                Chunk(; a = 3, b = 2)
            ]

            parms = (
                mmp = false,
                δ = 1,
                noise = false,
                τ = -10
            )

            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            requested = retrieval_request(actr; a = 1)

            @test length(requested) == 1
            @test requested[1].slots.a == 1
        end

        @safetestset "negation requested mmp false" begin
            using ACTRModels
            using Test

            chunks = [
                Chunk(; a = 1, b = 2),
                Chunk(; a = 2, b = 2),
                Chunk(; a = 3, b = 2)
            ]

            parms = (
                mmp = false,
                δ = 1,
                noise = false,
                τ = -10
            )

            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            requested = retrieval_request(actr; funs = (≠,), a = 1)

            @test length(requested) == 2
            @test requested[1].slots.a == 2
            @test requested[2].slots.a == 3
        end

        @safetestset "blending" begin
            using ACTRModels, Test, Random, Distributions
            Random.seed!(652)
            chunks = [Chunk(; a = 2, b = 0), Chunk(; a = 1, b = 3)]
            parms = (mmp = true, δ = 1.0, noise = true, s = 0.2)
            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            request = (a = 2,)
            funs = (≠,)
            blended_slots = :b
            n_sim = 10_000
            mean_value1 =
                map(_ -> blend_chunks(actr, blended_slots; funs, request...), 1:n_sim) |>
                mean
            # should be weighted more towards 3 than 0
            @test mean_value1 ≈ 2.75 atol = 0.01
        end

        @safetestset "blend_slots non-numeric" begin
            using ACTRModels, Test, Random, Distributions
            Random.seed!(652)
            chunks = [Chunk(; a = :a, b = 0), Chunk(; a = :c, b = 3)]
            parms = (mmp = true, δ = 1.0, noise = true, s = 0.2)
            declarative = Declarative(; memory = chunks)
            actr = ACTR(; declarative, parms...)

            request = (a = :a,)
            funs = (≠,)
            blended_slots = [:a, :b]
            n_sim = 10_000
            blended_values =
                map(_ -> blend_chunks(actr, blended_slots; funs, request...), 1:n_sim)
            # should be weighted more towards 3 than 0
            @test mean(map(x -> x[1] == :c, blended_values)) ≥ 0.90
            @test mean(map(x -> x[2], blended_values)) ≥ 1.5
        end
    end
end
