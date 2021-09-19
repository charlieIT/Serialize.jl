using Serialize

@serialize Client
@serialize Person
@serialize Department
@serialize Car
@serialize Cat

@testset "Serialization tests       " begin

    @testset "Primitive serialization" begin
        # --- Examples for a struct with only primitive values (+ DateTime)
        cat      = Cat("Yuki", 3, 98.5, Dates.now())
        cat_bson = Mongoc.BSON(cat)
        @test cat_bson["name"]          == cat.name          # String
        @test cat_bson["age"]           == cat.age           # Int
        @test cat_bson["height"]        == cat.height        # Float
        @test cat_bson["date_of_birth"] == cat.date_of_birth # DateTime
    end

    @testset "Union serialization" begin
        # --- Holds a String
        car = Car("Mazerati")
        car_bson = Mongoc.BSON(car)
        @test car_bson["brand"] == car.brand

        # --- Holds an Int
        car = Car(10000)
        car_bson = Mongoc.BSON(car)
        @test car_bson["brand"] == car.brand
    end

    @testset "Composite serialization" begin
        # --- A struct that holds primitive and other user-defined types
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

    @testset "Dict serialization" begin
        # --- A struct that holds primitive, other user-defined types and Dict fields
        c = Client("Andre", 100, 1.5, Department("RAS"), [Car("Mazda"), Car("Ford")])
        p = Person(Dict("Andre" => c), Dict("tall" => 190), Dict("toys" => "car"))
        bson = Mongoc.BSON(p)
        
        bson_c = bson["name"]["Andre"]    
        @test bson_c["name"] == c.name
        @test bson_c["id"]   == c.id
        @test bson_c["tier"] == c.tier
        @test bson_c["dep"]["name"]  == c.dep.name
        for i in 1:length(c.cars)
            @test bson_c["cars"][i]["brand"] == c.cars[i].brand
        end
        @test bson["height"] == p.height
        @test bson["items"]  == p.items
    end
end

@testset "Deserialization tests     " begin

    @testset "Primitive deserialization" begin
        # --- A BSON that holds a struct with only primitive values (+ DateTime)
        cat_bson = Mongoc.BSON("""{ "name" : "Yuki", "age" : 3, "height" : 98.5, "date_of_birth" : { "\$date" : "2021-09-18T19:49:58.870Z" } }""")
        cat = Cat(cat_bson)
        @test cat.name          == cat_bson["name"]          
        @test cat.age           == cat_bson["age"]           
        @test cat.height        == cat_bson["height"]        
        @test cat.date_of_birth == cat_bson["date_of_birth"]
    end

    @testset "Union deserialization" begin
        # --- A BSON that holds a struct with Union values in fields
        car_bson = Mongoc.BSON("brand" => "Mazerati")
        car = Car(car_bson)
        @test car_bson["brand"] == car.brand
        car_bson = Mongoc.BSON("brand" => 10000)
        car = Car(car_bson)
        @test car_bson["brand"] == car.brand
    end

    @testset "Composite deserialization" begin
        # --- A BSON that holds a struct with other user-defined types
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

    @testset "Composition deserialization" begin
        # --- A BSON that holds a struct with primitive types, user-defined types and Dict fields
        bson_person = Mongoc.BSON(
            "name" => Dict("Andre" => 
                Dict("name" => "Andre", 
                    "id"    => 100, 
                    "tier"  => 1.5, 
                    "dep"   => Dict("name" => "RAS"), 
                    "cars"  => [Dict("brand" => "Mazda"), Dict("brand" => "Ford")])),
            "height" => Dict("tall" => 190),
            "items"  => Dict("toys" => "car")
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
        @test p.height == bson_person["height"]
        @test p.items  == bson_person["items"]
    end

end

# function profiling()
#     println("----- Performance Serialize------")    
#     c1 = Client("Andre", 100, 1.5, Department("RAS"), [Car("Mazda"), Car("Ford")])
#     c2 = Client("Luis", 100, 1.5, Department("RAS"), [Car("Mazda"), Car("Ford")])
#     p = Person(Dict("test" => c1))
#     car = Car("hello")
#     @time Car("hello") # -- for time to compile timing functions
#     println("----- [Serialization] Client - 1st Execution ------")    
#     @time c1_bson  = Mongoc.BSON(c1)
#     @time c2_bson  = Mongoc.BSON(c2)
#     # println("----- [Serialization] Person - 1st Execution ------")       
#     # @time p_bson  = Mongoc.BSON(p)
#     # @time p_bson  = Mongoc.BSON(p)
#     println("----- [Serialization] Car - 1st Execution ------")       
#     @time car_bson  = Mongoc.BSON(car)
#     @time car_bson  = Mongoc.BSON(car)
#     println("----- [Deserialization] Client - 1st Execution ------")       
#     @time c1_deser = Client(c1_bson)
#     @time c2_deser = Client(c2_bson)
#     # println("----- [Deserialization] Person - 1st Execution ------")      
#     # @time p_deser = Person(p_bson)
#     # @time p_deser = Person(p_bson)
#     println("----- [Deserialization] Car - 1st Execution ------")      
#     @time car_deser = Car(car_bson)
#     @time car_deser = Car(car_bson)

#     println("----------------------")
# end
# profiling()

