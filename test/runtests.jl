tests = ["Memory_Tests", "Utility_Tests"]

for test in tests
    include(test * ".jl")
end
