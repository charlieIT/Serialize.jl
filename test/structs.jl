struct Department
    name    ::String
end

struct Car
    brand   ::Union{Int, String}
end

struct Client
    name    ::String
    id      ::Int64
    tier    ::Float64
    dep     ::Department
    cars    ::Vector{Car}
end

struct Person
    name::Dict{String, Client}
end

struct Cat
    name          ::String
    age           ::Int
    height        ::Float64
    date_of_birth ::DateTime
end

struct SimpleDict
    name::Dict{String, String}
end

struct AUnionType
    name::Union{Nothing, Int, String}
end

struct ADictUnionType
    name::Dict{String, Union{Nothing, Int, String}}
end