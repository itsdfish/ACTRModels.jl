using SafeTestsets

@safetestset "Utility Tests" begin

    @safetestset "find_index" begin
        using ACTRModels, Test
        include("Utility_Functions.jl")

        chunks = populateMemory()
        declarative = Declarative(memory=chunks)
        actr = ACTR(declarative = declarative)
        idx = find_index(actr; attribute = :wings)
        @test chunks[idx].slots.attribute == :wings
        @test chunks[idx].slots.object == :bird
        @test chunks[idx].slots.value == :True

        idx = find_index(actr, ==, !=; attribute = :locomotion, value = :swimming)
        @test chunks[idx].slots.value == :flying
        @test chunks[idx].slots.object == :bird
        @test chunks[idx].slots.attribute == :locomotion
    end

    @safetestset "find_indices" begin
        using ACTRModels, Test
        include("Utility_Functions.jl")
        idx = find_indices(actr; attribute = :locomotion, value = :swimming)
        @test length(idx) == 3
        chunk_set = chunks[idx]
        @test all(x->x.slots.attribute == :locomotion && x.slots.value == :swimming, chunk_set)

        idx = find_indices(actr, ==, !=; attribute = :category, value = :bird)
        @test length(idx) == 4
        chunk_set = chunks[idx]
        @test all(x->x.slots.attribute == :category && x.slots.value != :bird, chunk_set)
    end
end
