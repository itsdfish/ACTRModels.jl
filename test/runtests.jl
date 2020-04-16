tests = [
"Memory Tests",
"Log Normal Race Tests",
"Utility_Tests"
]

res = map(tests) do t
    @eval module $(Symbol("Test_", t))
        include($t * ".jl")
    end
end
