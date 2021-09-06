import Base: convert, setindex!, convert, push!
import Mongoc.BSON

macro serialize(type_name)
    return quote
        # --- serializate type to BSON
        function Mongoc.BSON(t::$(esc(type_name)))
            bson = Mongoc.BSON()
            [bson[string(f)] = getfield(t,f) for f in fieldnames(typeof(t))]
            return bson
        end

        # --- Called when setting a bson value of a key and the return type of getfield is not a primitive type
        function Base.setindex!(bson::Mongoc.BSON, value::$(esc(type_name)), k::AbstractString)
            bson[k] = Mongoc.BSON(value)
        end

        # --- deserialize type (dict -> type)
        function $(esc(type_name))(data::Dict)
            arr = []
            field_names = fieldnames($(esc(type_name)))
            
            # -- Ensures correct order of fieldnames so that the constructor is called correctly
            for i in 1:length(field_names)
                f   = field_names[i]
                val = data[string(f)]
                
                # Treat fields of type Dict{String, T}, where T is a composite type
                if val isa Dict
                    val_type = eltype(fieldtype($(esc(type_name)), i))
                    if length(val_type.types) == 2   # -- {String, T}
                        val_type = val_type.types[2] # -- get type 'T'
                        if !isprimitivetype(val_type) && val_type != String
                            val = $(esc(:convert_dict_field))(val_type, val) # -- Call constructor
                        end
                    end
                end
                # -----

                push!(arr, val)
            end

            # -- Calls default constructor
            return $(esc(type_name))(arr...) 
        end

        # -- Convert specific for Dict{String, T} fields
        function $(esc(:convert_dict_field))(::Type{$(esc(type_name))}, data::Dict)
            ret = Dict{String, $(esc(type_name))}()
            [ret[string(k)] = $(esc(type_name))(v) for (k,v) in data]
            return ret
        end

        # --- deserialize type (BSON -> type)
        function $(esc(type_name))(bson::Mongoc.BSON)
            return $(esc(type_name))(Mongoc.as_dict(bson))
        end
        
        # --- Called when building a composite type
        function Base.convert(::Type{$(esc(type_name))}, data::Dict)
            return $(esc(type_name))(data)
        end

        # --- Utility to push to Mongoc collection
        function Base.push!(collection::Mongoc.AbstractCollection, document::$(esc(type_name)))
            Base.push!(collection, Mongoc.BSON(document))
        end
    end
end
