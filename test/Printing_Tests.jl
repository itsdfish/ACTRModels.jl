using SafeTestsets

@safetestset "Printing" begin
    using ACTRModels, Test
    chunks = [Chunk(a=:a, b=:b, c=:c, bl=-1.0), Chunk(a=:a, b=:b, c=:a, bl=-1.0)]
    memory = Declarative(memory=chunks)
    τ = 0.0
    actr = ACTR(;declarative=memory, τ, noise=false)
    compute_activation!(actr)    
    import_printing()
    df = print_memory(actr)
    @test df.act_blc == [-1,-1]
    @test df.act_bll == [0,0]
    @test df.act == [-1,-1]
end