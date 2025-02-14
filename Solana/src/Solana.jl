module Solana


include("./Packages/Types.jl")
include("./Packages/GeneralServices.jl")
include("./Packages/Cryptography.jl")
include("./Packages/RPCServices.jl")
include("./Packages/TestValidatorServices.jl")

using JSON, Base64, Base58, HTTP, Logging

# function get_block(slot=nothing)
#     data = Dict(
#         "jsonrpc" => "2.0",
#         "id" => 1,
#         "method" => "getBlock",
#         "params" => [
#             slot === nothing ? "recent" : slot,
#             Dict(
#                 "encoding" => "json",
#                 "maxSupportedTransactionVersion" => 0,
#                 "transactionDetails" => "full",
#                 "rewards" => false
#             )
#         ]
#     )

#     try
#         response = HTTP.request(
#             "POST",
#             ENV["RPC_URL"],
#             ["Content-Type" => "application/json"],
#             body=JSON.json(data)
#         )

#         body = JSON.parse(String(response.body))

#         if haskey(body, "error")
#             @warn "Error fetching block: $(body["error"]["message"])"
#             return nothing
#         end

#         return body["result"]
#     catch e
#         @error "Exception occurred: $e"
#         return nothing
#     end
# end

# function get_latest_slot()
#     data = Dict(
#         "jsonrpc" => "2.0",
#         "id" => 1,
#         "method" => "getSlot",
#         "params" => []
#     )

#     response = HTTP.request(
#         "POST",
#         ENV["RPC_URL"],
#         ["Content-Type" => "application/json"],
#         body=JSON.json(data)
#     )

#     body = JSON.parse(String(response.body))
#     return body["result"]
# end

end