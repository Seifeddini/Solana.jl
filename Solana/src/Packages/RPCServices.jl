
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
            ENV["RPC_URL"],
            ["Content-Type" => "application/json"],
            body=JSON.json(data)
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
        ENV["RPC_URL"],
        ["Content-Type" => "application/json"],
        body=JSON.json(data)
    )

    body = JSON.parse(String(response.body))
    return body["result"]
end

function get_latest_blockhash()
    data = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getLatestBlockhash",
        "params" => []
    )

    try
        response = HTTP.request(
            "POST",
            ENV["RPC_URL"],
            ["Content-Type" => "application/json"],
            body=JSON.json(data)
        )

        body = JSON.parse(String(response.body))

        if haskey(body, "error")
            @warn "Error fetching latest blockhash: $(body["error"]["message"])"
            return nothing
        end

        return body["result"]
    catch e
        @error "Exception occurred: $e"
        return nothing
    end
end

function transfer_sol_async(from_wallet::Wallet, to_pubkey::String, amount::UInt64)
    # See for help: https://solana.com/de/docs/core/transactions

    # Create signatures and compress to compact array
    signatures::Array{String} = []
    push!(signatures, from_wallet.PrivateKey)

    # create message
    message_header::MessageHeader = MessageHeader(UInt8(1), UInt8(0), UInt8(0))
    account_keys::Array{String} = []

    push!(account_keys, from_wallet.Account.Pubkey)
    push!(account_keys, to_pubkey)

    # TODO WAL-29 - Create Strategy for Recent Blockhash choosing
    recent_blockhash = get_latest_blockhash()

    instructions::Array{Instruction} = []

    # create transfer instruction
    account_keys::Array{AccountMeta} = []

    push!(account_keys, AccountMeta(from_wallet.Account.Pubkey, true, true))
    push!(account_keys, AccountMeta(to_pubkey, false, true))

    instruction_id = 2
    data::Vector{UInt8} = Vector{UInt8}(undef, 4 + 8)
    data[1:4] = UInt32(instruction_id)
    data[5:end] = UInt64(amount)

    instruction::Instruction = Instruction(solana_programms["system"], account_keys, data)
    push!(instructions, instruction)

    instructions = to_compact_array(instructions)
    account_keys = to_compact_array(account_keys)
    message::Message = Message(message_header, account_keys, recent_blockhash, instructions)

    signatures = to_compact_array(signatures)
    transaction = Transaction(signatures, message)

    # required encoding for transactions
    transaction_string = String(transaction)

    # Send the transaction
    data = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "sendTransaction",
        "params" => [transaction_string]
    )

    try
        response = HTTP.request(
            "POST",
            ENV["RPC_URL"],
            ["Content-Type" => "application/json"],
            body=JSON.json(data)
        )

        body = JSON.parse(String(response.body))

        if haskey(body, "error")
            @warn "Error sending transaction: $(body["error"]["message"])"
            return nothing
        end

        return body["result"]
    catch e
        @error "Exception occurred: $e"
        return nothing
    end
end