
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

function create_wallet(name::String)::Wallet
    @debug "Start Wallet Creation"
    val = run(`solana-keygen new --force --no-bip39-passphrase --outfile  "~"/SolWallets/$name.json`)
    @debug "New Wallet created"

    private_key::String, public_key::String = read_wallet_keys("~/SolWallets/$name.json")
    @assert private_key isa String && public_key isa String "Private key or Public Key is not a string"
    return Wallet(name, public_key, private_key)
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