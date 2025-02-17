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

function generate_instruction(accounts::Array{AccountMeta}, program_id::String, data::Vector{UInt8})
    return Instruction(program_id, accounts, data)
end

function transfer_sol_generate_message(from_wallet::Wallet, to_pubkey::String, amount::UInt64)

    # create message
    message_header::MessageHeader = MessageHeader(UInt8(1), UInt8(0), UInt8(0))

    account_keys::Array{String} = []
    push!(account_keys, from_wallet.Account.Pubkey)
    push!(account_keys, to_pubkey)

    # TODO WAL-29 - Create Strategy for Recent Blockhash choosing
    recent_blockhash::String = get_latest_blockhash()["value"]["blockhash"]

    instructions::Array{Instruction} = []
    # create transfer instruction

    accounts::Array{AccountMeta} = []

    push!(accounts, AccountMeta((Vector{UInt8})(from_wallet.Account.Pubkey), (UInt8)(true), (UInt8)(true)))
    push!(accounts, AccountMeta((Vector{UInt8})(to_pubkey), (UInt8)(false), (UInt8)(true)))
    instruction_id = 2

    data_buffer = IOBuffer()
    write(data_buffer, UInt32(instruction_id))
    write(data_buffer, UInt64(amount))
    data::Vector{UInt8} = take!(data_buffer)


    instruction::Instruction = Instruction((Vector{UInt8})(solana_programms["system"]), serialize(accounts, UInt32), data)
    push!(instructions, instruction)

    ser_instructions = to_compact_array(instructions, UInt32)
    ser_account_keys = to_compact_array(account_keys, UInt32)
    ser_messsage_header = serialize_struct(message_header, UInt8)
    ser_recent_blockhash = Vector{UInt8}(recent_blockhash)
    @assert length(ser_recent_blockhash) == 32 "ser_recent_blockhash must have exactly 32 bytes"
    message::Message = Message(ser_messsage_header, ser_account_keys, ser_recent_blockhash, ser_instructions)
    return message
end

function transfer_sol_async(from_wallet::Wallet, to_pubkey::String, amount::UInt64)
    # See for help: https://solana.com/de/docs/core/transactions

    # Create signatures and compress to compact array
    signatures::Array{String} = []
    push!(signatures, from_wallet.PrivateKey)

    message = transfer_sol_generate_message(from_wallet, to_pubkey, amount)

    ser_signatures = serialize(signatures, UInt64)
    ser_message = Vector{UInt8}(message)
    transaction::Transaction = Transaction(ser_signatures, set_message)

    # required encoding for transactions
    transaction_bytes = serialize_struct(transaction)

    transaction_string = base58_encode(transaction_bytes)

    # Send the transaction
    http_data = Dict(
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
            body=JSON.json(http_data)
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