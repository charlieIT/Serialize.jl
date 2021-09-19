module MyApp
    using Test
    using Mongoc
    using Serialize

    export Hello, Other, exec

    # ----- setup
    struct Hello
        id  ::Int
        msg ::String
    end

    struct Other
        hello::Dict{String, Hello}
    end

    @serialize Hello
    @serialize Other
    # ------------------
    
    # ------ Business functions ----------
    function exec()
        h = Hello(100, "hello")
        o = Other(Dict("h" => h))
        return [bson(h), bson(o)]
    end
    # ------------------

    module InnerMod
        using ..MyApp
        using Test
        @testset "Outer module defines types" begin
            # -- interface with datatypes by using well-defined "interface" functions
            ret = exec()
            @test ret[1]["id"]    == 100
            @test ret[1]["msg"]   == "hello"
            @test ret[2]["hello"] == Dict("h" => Dict("id" => 100, "msg" => "hello"))
            
            # -- interface with datatypes by using outer-definition (non-exported functions)
            h = MyApp.Hello(100, "hello")
            o = MyApp.Other(Dict("h" => h))
            h_bson = MyApp.bson(h)
            o_bson = MyApp.bson(o)
            @test h_bson["id"]    == 100
            @test h_bson["msg"]   == "hello"
            @test o_bson["hello"] == Dict("h" => Dict("id" => 100, "msg" => "hello"))
            h = Hello(h_bson)
            o = Other(o_bson)
            @test  h.id    == 100
            @test  h.msg   == "hello"
            @test  o.hello == Dict("h" => Hello(100, "hello"))
            
            # -- interface with datatypes by using constructors (must be exported, otherwise use fully qualified name)
            h = Hello(100, "hello")
            o = Other(Dict("h" => h))
            @test  h.id     == 100
            @test  h.msg    == "hello"
            @test  o.hello == Dict("h" => Hello(100, "hello"))
        end
    end
end


# ------------------------------------------------

module MyMainApp
    
    module InnerMod
        using Mongoc
        using Serialize

        export Hello, Other, exec

        # ----- setup
        struct Hello
            id  ::Int
            msg ::String
        end

        struct Other
            hello::Dict{String, Hello}
        end

        @serialize Hello
        @serialize Other
        # ------------------
        
        # ------ Business functions ----------
        function exec()
            h = Hello(100, "hello")
            o = Other(Dict("h" => h))
            return [bson(h), bson(o)]
        end
    end

    using .InnerMod
    using Test

    @testset "Inner module defines types" begin
        # -- interface with datatypes by using well-defined "interface" functions
        ret = exec()
        @test ret[1]["id"]    == 100
        @test ret[1]["msg"]   == "hello"
        @test ret[2]["hello"] == Dict("h" => Dict("id" => 100, "msg" => "hello"))
        
        # -- interface with datatypes by using inner-definition (non-exported functions)
        h = InnerMod.Hello(100, "hello")
        o = InnerMod.Other(Dict("h" => h))
        h_bson = InnerMod.bson(h)
        o_bson = InnerMod.bson(o)
        @test h_bson["id"]    == 100
        @test h_bson["msg"]   == "hello"
        @test o_bson["hello"] == Dict("h" => Dict("id" => 100, "msg" => "hello"))
        h = Hello(h_bson)
        o = Other(o_bson)
        @test  h.id    == 100
        @test  h.msg   == "hello"
        @test  o.hello == Dict("h" => Hello(100, "hello"))

        # -- interface with datatypes by using constructors (must be exported, otherwise use fully qualified name)
        h = Hello(100, "hello")
        o = Other(Dict("h" => h))
        @test  h.id    == 100
        @test  h.msg   == "hello"
        @test  o.hello == Dict("h" => Hello(100, "hello"))
    end
end

