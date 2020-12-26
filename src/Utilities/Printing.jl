using DataFrames
"""
**print_memory** prints all chunks in declarative memory and returns a DataFrame.
- `actr`: an ACTR object
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function Signature
````julia
print_memory(actr::AbstractACTR; fields=(:slots,:act_blc,:act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_memory(actr::AbstractACTR; fields=(:slots,:act_blc,:act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    return print_memory(actr.declarative; fields=fields)
end

"""
**print_memory** prints all chunks in declarative memory and returns a DataFrame.
- `memory`: a declarative memory object
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function Signature
````julia
print_memory(memory::Declarative; fields=(:slots,:act_blc,:act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_memory(memory::Declarative; fields=(:slots,:act_blc,:act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    return print_memory(memory.memory; fields=fields)
end

"""
**print_memory** prints all chunks in declarative memory and returns a DataFrame.
- `chunks`: a vector of chunks
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function Signature
````julia
print_memory(chunks; fields=(:slots,:act_blc,:act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_memory(chunks; fields=(:slots,:act_blc,:act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    df = DataFrame(chunks)
    slots = map(x->x.slots, chunks)
    df_slots = DataFrame()
    for chunk in chunks
        push!(df_slots, chunk.slots; cols=:union)
    end
    fields == :all ? nothing : select!(df, fields...)
    df = [df_slots df]
    select!(df, Not(:slots))
    return df
end

"""
**print_chunk** prints the contents of a chunk and returns a DataFrame.
- `chunk`: a chunk
- `fields`: a keyword argument of tuple of symbols of fields to print. See function signature below for default values.
    Pass fields = :all to print all fields.

Function Signature
````julia
print_chunk(chunk; fields=(:slots,:act_blc, :act_bll,:act_pm,:act_sa,:act_noise,:act))
````
"""
function print_chunk(chunk; fields=(:slots,:act_blc, :act_bll,
    :act_pm,:act_sa,:act_noise,:act))
    return print_memory([chunk]; fields=fields)
end