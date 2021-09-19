module Serialize

export @serialize
export bson

using JSON
using Mongoc

include("adapters/MongoDB.jl")

end # module
