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

# TODO fill arguments
function submit_transaction()
    # See for help: https://solana.com/de/docs/core/transactions

    # TODO fill arguments
    transaction = create_transaction()
    transaction_string = serialize_transaction(transaction)

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

