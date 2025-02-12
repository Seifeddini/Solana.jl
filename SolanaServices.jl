module SolanaServices

include("SolanaTypes.jl")
using .SolanaTypes

function get_block(slot=nothing)
    data = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getBlock",
        "params" => [
            slot === nothing ? "recent" : slot,
            Dict(
                "encoding" => "json",
                "maxSupportedTransactionVersion" => 0,
                "transactionDetails" => "full",
                "rewards" => false
            )
        ]
    )

    try
        response = HTTP.request(
            "POST",
            RPC_URL,
            ["Content-Type" => "application/json"],
            body = JSON.json(data)
        )

        body = JSON.parse(String(response.body))

        if haskey(body, "error")
            @warn "Error fetching block: $(body["error"]["message"])"
            return nothing
        end

        return body["result"]
    catch e
        @error "Exception occurred: $e"
        return nothing
    end
end

function get_latest_slot()
    data = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getSlot",
        "params" => []
    )

    response = HTTP.request(
        "POST",
        RPC_URL,
        ["Content-Type" => "application/json"],
        body = JSON.json(data)
    )

    body = JSON.parse(String(response.body))
    return body["result"]
end

function create_token()
    output = read(`spl-token create-token`, String)
    
    address = match(r"Address:\s+(\w+)", output).captures[1]
    program = match(r"under program\s+(\w+)", output).captures[1]
    decimals = parse(Int, match(r"Decimals:\s+(\d+)", output).captures[1])
    signature = match(r"Signature:\s+(\w+)", output).captures[1]
    
    return Dict(
        "address" => address,
        "program" => program,
        "decimals" => decimals,
        "signature" => signature
    )
end

function create_token_account(token_address)
    output = read(`spl-token create-account $token_address`, String)
    
    account_address = match(r"Creating account\s+(\w+)", output).captures[1]
    signature = match(r"Signature:\s+(\w+)", output).captures[1]
    
    return Dict(
        "account_address" => account_address,
        "signature" => signature
    )
end

function mint_token(token_address, amount)
    output = read(`spl-token mint $token_address $amount`, String)
    return true;
end

function check_token_balance(token_address)
    output = read(`spl-token balance $token_address`, Int)
    return output
end

function create_wallet(name::String)::Wallet
    @info "Start Wallet Creation"
    
    val = run(`solana-keygen new --force --no-bip39-passphrase --outfile  "~"/SolWallets/$name.json`)
    println("VAL: $val")
    @info "New Wallet created"

    public_key = read(`solana-keygen pubkey "~"/SolWallets/$name.json`, String)
    public_key = chomp(public_key)
    return public_key
end

function airdrop_sol(pubkey, amount::Int)

    payload = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "requestAirdrop",
        "params" => [pubkey, string(amount)]
    )
    
    response = HTTP.post(RPC_URL, 
                         ["Content-Type" => "application/json"],
                         JSON.json(payload))
                         
    @info "Airdropped $amount lamports to $pubkey. Amount in SOL: " amount / 10^9
    
    return JSON.parse(String(response.body))

end

function get_balance(pubkey)
    # Create the payload for the JSON RPC request
    payload = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getBalance",
        "params" => [pubkey]
    )

    # Send the HTTP POST request to the local test validator
    response = HTTP.post(RPC_URL, ["Content-Type" => "application/json"], JSON.json(payload))
    
    # Parse and return the response
    result = JSON.parse(String(response.body))
    if haskey(result, "result") && haskey(result["result"], "value")
        return result["result"]["value"]  # Balance in lamports
    else
        error("Failed to fetch balance: ", result)
    end
end

end