tests = [
"Memory_Tests",
"Log_Normal_Race_Tests",
"Utility_Tests"
]

res = map(tests) do t
    @eval module $(Symbol("Test_", t))
        include($t * ".jl")
    end
end
