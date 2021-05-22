tests = [
    "Memory_Tests",
    "Utility_Tests",
    "Printing_Tests",]

for test in tests
    include(test * ".jl")
end
