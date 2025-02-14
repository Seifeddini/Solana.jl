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