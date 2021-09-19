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
    name    ::Dict{String, Client}
    height  ::Dict{String, Int}
    items   ::Dict{String, String}
end

struct Cat
    name          ::String
    age           ::Int
    height        ::Float64
    date_of_birth ::DateTime
end

