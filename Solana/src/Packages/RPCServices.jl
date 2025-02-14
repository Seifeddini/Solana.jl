
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