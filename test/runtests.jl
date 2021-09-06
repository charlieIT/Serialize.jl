using Test
using Serialize
using Mongoc

struct Department
    name    ::String
end

struct Car
    brand   ::String
end

struct Client
    name    ::String
    id      ::Int
    tier    ::Float64
    dep     ::Department
    cars    ::Vector{Car}
end

struct Person
    name::Dict{String, Client}
end

@serialize Client
@serialize Person
@serialize Department
@serialize Car

@testset "Serialization tests" begin

    @testset "simple serialization       " begin
        c = Client("Andre", 100, 1.5, Department("RAS"), [Car("Mazda"), Car("Ford")])
        bson = Mongoc.BSON(c)
        @test bson["name"] == c.name
        @test bson["id"]   == c.id
        @test bson["tier"] == c.tier
        @test bson["dep"]["name"]  == c.dep.name
        for i in 1:length(c.cars)
            @test bson["cars"][i]["brand"] == c.cars[i].brand
        end
    end

    @testset "composition serialization  " begin
        c = Client("Andre", 100, 1.5, Department("RAS"), [Car("Mazda"), Car("Ford")])
        p = Person(Dict("Andre" => c))
        bson = Mongoc.BSON(p)
        
        bson = bson["name"]["Andre"]    
        @test bson["name"] == c.name
        @test bson["id"]   == c.id
        @test bson["tier"] == c.tier
        @test bson["dep"]["name"]  == c.dep.name
        for i in 1:length(c.cars)
            @test bson["cars"][i]["brand"] == c.cars[i].brand
        end
    end
end

@testset "Deserialization tests" begin

    @testset "simple deserialization     " begin
        bson = Mongoc.BSON("name" => "Andre", "id" => 100, "tier" => 1.5, "dep" => Dict("name" => "RAS"), "cars" => [Dict("brand" => "Mazda"), Dict("brand" => "Ford")] )
        c = Client(bson)
        @test c.name     == bson["name"] 
        @test c.id       == bson["id"]
        @test c.tier     == bson["tier"]
        @test c.dep.name == bson["dep"]["name"]
        for i in 1:length(bson["cars"])
            @test c.cars[i].brand == bson["cars"][i]["brand"] 
        end
    end

    @testset "composition deserialization" begin
        
        bson_person = Mongoc.BSON(
            "name" => Dict("Andre" => 
                Dict("name" => "Andre", 
                    "id"    => 100, 
                    "tier"  => 1.5, 
                    "dep"   => Dict("name" => "RAS"), 
                    "cars"  => [Dict("brand" => "Mazda"), Dict("brand" => "Ford")])) 
        )

        p = Person(bson_person)

        c = p.name["Andre"]
        bson_client = bson_person["name"]["Andre"]
        @test c.name     == bson_client["name"]
        @test c.id       == bson_client["id"]
        @test c.tier     == bson_client["tier"]
        @test c.dep.name == bson_client["dep"]["name"]
        for i in 1:length(bson_client["cars"])
            @test c.cars[i].brand == bson_client["cars"][i]["brand"] 
        end
    end

end

println("----- Performance ------")    
c = Client("Andre", 100, 1.5, Department("RAS"), [Car("Mazda"), Car("Ford")])
p = Person(Dict("test" => c))
@time c_bson  = Mongoc.BSON(c)
@time p_bson  = Mongoc.BSON(p)
@time c_deser = Client(c_bson)
@time p_deser = Person(p_bson)
println("----------------------")
