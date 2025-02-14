module Solana

# include("SolanaTypes.jl")
# using .SolanaTypes
using JSON, Base64, Base58, HTTP, Logging

export AccountMeta, Instruction, MessageHeader, Message, Transaction, Wallet, TokenAccount, Token

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

function create_token()
    try
        output = read(`spl-token create-token`, String)

        address = match(r"Address:\s+(\w+)", output).captures[1]
        program = match(r"under program\s+(\w+)", output).captures[1]
        decimals = parse(Int, match(r"Decimals:\s+(\d+)", output).captures[1])
        signature = match(r"Signature:\s+(\w+)", output).captures[1]

        return Token(address, program, decimals, signature)
    catch e
        @error "Exception occurred: $e"
        return nothing
    end
end

function create_token_account(token_address)::TokenAccount
    try
        output = read(`spl-token create-account $token_address`, String)

        account_address = match(r"Creating account\s+(\w+)", output).captures[1]
        signature = match(r"Signature:\s+(\w+)", output).captures[1]

        return TokenAccount(account_address, signature)
    catch e
        @error "Exception occurred: $e"
        return nothing
    end
end

function mint_token(token_address::String, amount::Int, target_state="confirmed", wait_time::Float64=30.0)
    try
        output = read(`spl-token mint $token_address $amount`, String)
        signature = String(match(r"Signature:\s+(\w+)", output).captures[1])

        #confirmation = @async confirm_transaction(signature, target_state, wait_time)

        return signature
    catch e
        @error "Exception occurred: $e"
        return false
    end
end

function check_token_balance(token_address)
    try
        output = read(`spl-token balance $token_address`, String)
        balance = parse(Int, match(r"\d+", output).match)
        @debug "Output of check token balance: \n $balance \n \n ------"
        return balance
    catch e
        @error "Exception occurred: $e"
        return nothing
    end
end

function base58_encode(data::Vector{UInt8})
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = BigInt(0)

    # Convert byte array to BigInt
    for byte in data
        num = num * 256 + byte
    end

    # Encode to Base58
    encoded = ""
    while num > 0
        num, remainder = divrem(num, 58)
        encoded = alphabet[remainder+1] * encoded
    end

    # Add leading '1's for each leading zero byte in the input
    for byte in data
        if byte == 0
            encoded = "1" * encoded
        else
            break
        end
    end

    return encoded
end

function read_wallet_keys(filename::String)
    # Read and parse the JSON file
    json_data = JSON.parsefile(filename)

    # Convert the integer array to bytes
    byte_array = UInt8.(json_data)

    # Extract private and public keys
    private_key_bytes = byte_array[1:32]
    public_key_bytes = byte_array[33:end]

    public_key_string = base58_encode(public_key_bytes)
    private_key_string = base58_encode(private_key_bytes)

    return private_key_string, public_key_string
end

function create_wallet(name::String)::Wallet
    @debug "Start Wallet Creation"
    val = run(`solana-keygen new --force --no-bip39-passphrase --outfile  "~"/SolWallets/$name.json`)
    @debug "New Wallet created"

    private_key, public_key = read_wallet_keys("~/SolWallets/$name.json")

    return Wallet(name, public_key, private_key)
end

function get_signature_statuses(signatures::Vector{String})
    payload = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getSignatureStatuses",
        "params" => [signatures]
    )

    try
        response = HTTP.post(ENV["RPC_URL"],
            ["Content-Type" => "application/json"],
            JSON.json(payload))

        result = JSON.parse(String(response.body))

        return result["result"]
    catch e
        @error "An error occured: $e"
        return nothing
    end
end

function confirm_transaction(signature::String, target_status="confirmed", limit::Float64=30.0)

    if signature === nothing
        return nothing
    end

    sleep_timer::Float64 = 1.0

    status = get_signature_statuses([signature])
    status = status["value"]

    while !(typeof(status[1]) <: Dict) || (typeof(status[1]) <: Dict && status[1]["confirmationStatus"] != target_status)

        # Timeout-condition
        if sleep_timer > limit
            @error "Airdrop transaction timed out"
            return nothing
        end

        sleep(sleep_timer)
        sleep_timer *= 1.5
        status = get_signature_statuses([signature])
        status = status["value"]

        @debug "Waiting for confirmation... \n $status"
    end

    return signature
end


function airdrop_sol_async(pubkey, amount::Int, target_status="confirmed")
    # TODO Track transactions
    payload = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "requestAirdrop",
        "params" => [pubkey, amount]
    )

    try
        response = HTTP.post(ENV["RPC_URL"],
            ["Content-Type" => "application/json"],
            JSON.json(payload))

        result = JSON.parse(String(response.body))

        if haskey(result, "error")
            @error "Failed to airdrop SOL: $(result["error"]["message"])"
            return nothing
        end

        @debug "Airdropped $amount lamports to $pubkey. Amount in SOL: " amount / 10^9

        signature = result["result"]

        waiting_task = @async confirm_transaction(signature, target_status)

        # Return Signature of the transaction
        return waiting_task
    catch e
        @error "Exception occurred: $e"
        return nothing
    end
end

function get_balance(pubkey, status="confirmed")
    # Create the payload for the JSON RPC request
    payload = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getBalance",
        "params" => [pubkey, Dict("commitment" => status)]
    )

    try
        # Send the HTTP POST request to the local test validator
        response = HTTP.post(ENV["RPC_URL"], ["Content-Type" => "application/json"], JSON.json(payload))

        # Parse and return the response
        result = JSON.parse(String(response.body))

        if haskey(result, "result") && haskey(result["result"], "value")
            return result["result"]["value"]  # Balance in lamports
        else
            error("Failed to fetch balance: ", result)
        end
    catch e
        error("Failed to fetch balance: $e")
    end
end


# STRUCTS

struct AccountMeta
    pubkey::Vector{UInt8}
    is_signer::Bool
    is_writable::Bool
end

struct Instruction
    program_id::Vector{UInt8}
    accounts::Vector{AccountMeta}
    data::Vector{UInt8}
end

struct MessageHeader
    num_required_signatures::UInt8
    num_readonly_signed_accounts::UInt8
    num_readonly_unsigned_accounts::UInt8
end

struct Message
    header::MessageHeader
    account_keys::Vector{Vector{UInt8}}
    recent_blockhash::Vector{UInt8}
    instructions::Vector{Instruction}
end

struct Transaction
    signatures::Vector{Vector{UInt8}}
    message::Message
end

struct Wallet
    name::String
    pubkey::String
    secretkey::String
end

struct TokenAccount
    account_address::String
    signature::String
end

struct Token
    address::String
    program::String
    decimals::Int
    signature::String
end
end