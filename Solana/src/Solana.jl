module Solana


include("./Packages/Types.jl")
include("./Packages/GeneralServices.jl")
include("./Packages/Cryptography.jl")
include("./Packages/TransactionServices.jl")
include("./Packages/RPCServices.jl")
include("./Packages/TestValidatorServices.jl")

using JSON, Base64, Base58, HTTP, Logging

solana_programms = Dict(
    "system" => "11111111111111111111111111111111",
    "token_program" => "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
)

end