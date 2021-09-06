module Serialize

export @serialize
export convert_dict_field

using JSON
using Mongoc

include("adapters/MongoDB.jl")

end # module
