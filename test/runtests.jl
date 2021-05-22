tests = [
    "Memory_Tests",
    "Utility_Tests",
    "Printing_Tests",
    "simulator"
]

for test in tests
    include(test * ".jl")
end
