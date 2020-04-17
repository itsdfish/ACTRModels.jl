using SafeTestsets

@safetestset "Utility Tests" begin

    @safetestset "findIndex" begin
        using ACTRModels, Test
        include("Utility_Functions.jl")

        chunks = populateMemory()
        declarative = Declarative(memory=chunks)
        actr = ACTR(declarative = declarative)
        idx = findIndex(actr; attribute = :wings)
        @test chunks[idx].slots.attribute == :wings
        @test chunks[idx].slots.object == :bird
        @test chunks[idx].slots.value == :True

        idx = findIndex(actr, ==, !=; attribute = :locomotion, value = :swimming)
        @test chunks[idx].slots.value == :flying
        @test chunks[idx].slots.object == :bird
        @test chunks[idx].slots.attribute == :locomotion
    end

    @safetestset "findIndices" begin
        using ACTRModels, Test
        include("Utility_Functions.jl")

        chunks = populateMemory()
        declarative = Declarative(memory=chunks)
        actr = ACTR(declarative = declarative)
        idx = findIndices(actr; attribute = :locomotion, value = :swimming)
        @test length(idx) == 3
        chunk_set = chunks[idx]
        @test all(x->x.slots.attribute == :locomotion && x.slots.value == :swimming, chunk_set)

        idx = findIndices(actr, ==, !=; attribute = :category, value = :bird)
        @test length(idx) == 4
        chunk_set = chunks[idx]
        @test all(x->x.slots.attribute == :category && x.slots.value != :bird, chunk_set)
    end
end
