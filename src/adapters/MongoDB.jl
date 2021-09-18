import Base: convert, setindex!, convert, push!
import Mongoc.BSON

macro serialize(type_name)
    return quote
        # --- serialize type to BSON 
        # --- ex: Mongoc.BSON(t::Client)
        function Mongoc.BSON(t::$(esc(type_name)))
            return Mongoc.BSON([string(f) => getfield(t,f) for f in fieldnames($(esc(type_name)))]...)
        end

        # --- Called when setting a bson value of a key and the return type of getfield is not a primitive type
        # --- ex: Base.setindex!(bson::Mongoc.BSON, value::Client, k::AbstractString)
        function Base.setindex!(bson::Mongoc.BSON, value::$(esc(type_name)), k::AbstractString)
            bson[k] = Mongoc.BSON(value)
        end
        
        # --- deserialize type (dict -> type)
        # --- ex: Client(data::Dict)
        function $(esc(type_name))(data::Dict)
            arr = []
            # -- Ensures correct order of fieldnames so that the constructor is called correctly
            for f in fieldnames($(esc(type_name)))
                
                # Throw meaningful exception when deserialization doesnt have full information
                # if haskey(data, string(f))
                val = data[string(f)]
                
                if fieldtype($(esc(type_name)), f) <: Dict # -- field of struct is itself a dict, then convert it based on its type
                    val_type = eltype(fieldtype($(esc(type_name)), f)).types[2] # -- From {String, T} get type 'T'
                    val      = Dict{String, val_type}([k => val_type(v) for (k,v) in val])
                end
                
                push!(arr, val)
            end
            
            # -- Calls default constructor (converts will take care of deserializing the fields (if needed))
            return $(esc(type_name))(arr...) 
        end

        # --- deserialize type (BSON -> type)
        # --- Client(bson::Mongoc.BSON)
        function $(esc(type_name))(bson::Mongoc.BSON)
            return $(esc(type_name))(Mongoc.as_dict(bson))
        end
        
        # --- Called when building a composite type
        # --- Base.convert(::Type{Client}, data::Dict)
        function Base.convert(::Type{$(esc(type_name))}, data::Dict)
            return $(esc(type_name))(data)
        end

        # --- Utility to push to Mongoc collection
        # --- Base.push!(collection::Mongoc.AbstractCollection, document::Client)
        function Base.push!(collection::Mongoc.AbstractCollection, document::$(esc(type_name)))
            Base.push!(collection, Mongoc.BSON(document))
        end
    end
end
