

pip_sol = @pyimport("./pip_sol")
# -------------------------------------------
function serialize(arr::Array{T}) where {T}
    buffer = IOBuffer()

    for elem in arr
        if elem isa AbstractArray
            serialized_elem = serialize(elem)
            write(buffer, serialized_elem)
        else
            write(buffer, elem)
        end
    end

    return take!(buffer)
end

struct CompactU16
    value::UInt16
end
export CompactU16

function Base.write(io::IO, cu::CompactU16)
    rem_val = cu.value
    while true
        elem = UInt8(rem_val & 0x7f)
        rem_val >>= 7
        if rem_val == 0
            write(io, elem)
            break
        else
            write(io, elem | 0x80)
        end
    end
end

function Base.read(io::IO, ::Type{CompactU16})
    val = UInt16(0)
    for i in 0:2
        elem = read(io, UInt8)
        val |= UInt16(elem & 0x7f) << (i * 7)
        if (elem & 0x80) == 0
            return CompactU16(val)
        end
    end
    throw(ErrorException("Invalid CompactU16 encoding"))
end

function encode_compact_u16(value::UInt16)
    io = IOBuffer()
    write(io, CompactU16(value))
    return take!(io)
end

function decode_compact_u16(bytes::Vector{UInt8})
    io = IOBuffer(bytes)
    return read(io, CompactU16).value
end

function to_compact_array(arr::Array{T}) where {T}
    io = IOBuffer()
    write(io, CompactU16(UInt16(length(arr))))

    write(io, serialize(arr))
    return take!(io)
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

function serialize_instruction(collector::Array, instruction::Instruction, pubkeys::Array{String})
    buffer = IOBuffer()
    program_index::UInt8 = 0
    account_indices::Array{UInt8} = []

    index = 0
    for account in pubkeys
        if program_index == 0 && account == instruction.ProgramId
            program_index = index
        else
            for account_sub in account_indices
                if account == account_sub
                    push!(account_indices, index)
                    break
                end
            end
        end
        index += 1
    end

    write(buffer, program_index)

    for account_index in account_indices
        write(buffer, account_index)
    end

    write(buffer, instruction.Data)

    push!(collector, take!(buffer))
end

function serialize_transaction(transaction::Transaction)
    buffer = IOBuffer()
    # serialize Signatures
    serialized_sigs = to_compact_array(transaction.Signatures)

    message_buffer = IOBuffer()
    # serialize Header
    header_buffer = IOBuffer()
    write(header_buffer, transaction.Message.Header.NumRequiredSignatures)
    write(header_buffer, transaction.Message.Header.NumReadonlySignedAccounts)
    write(header_buffer, transaction.Message.Header.NumReadonlyUnsignedAccounts)
    header_bytes = take!(header_buffer)
    # serialize Account-keys
    account_keys_bytes = to_compact_array(transaction.Message.AccountKeys)
    # seralize Recent Blockhash
    blockhash_buffer = IOBuffer()
    write(blockhash_buffer, transaction.Message.RecentBlockhash)
    blockhash_bytes = take!(blockhash_buffer)
    # serialize Instructions
    instruction_array::Array{Vector{UInt8}} = []
    for instruction::Instruction in transaction.Message.Instructions
        serialize_instruction(instruction_array, instruction, transaction.Message.AccountKeys)
    end
    instruction_bytes = to_compact_array(instruction_array)
    # Serialize Message
    write(message_buffer, header_bytes)
    write(message_buffer, account_keys_bytes)
    write(message_buffer, blockhash_bytes)
    write(message_buffer, instruction_bytes)
    message_bytes = take!(message_buffer)

    # Finish Transaction_serialization
    write(buffer, serialized_sigs)
    write(buffer, message_bytes)

    transaction_bytes = take!(buffer)
    transaction_string = base58_encode(transaction_bytes)
    return transaction_string
end

function insert_wallet(wallets::Array{String}, account::AccountMeta, first_ind::Array{Int})

    first_signed_ro = first_ind[1]
    first_unsigned_ro = first_ind[2]

    if account.IsSigner && !account.IsWritable
        if first_signed_ro == -1
            push!(wallets, account.Pubkey)
            first_signed_ro = 1
        else
            insert!(wallets, first_signed_ro, account.Pubkey)
        end
    elseif !account.IsSigner && !account.IsWritable
        if first_unsigned_ro == -1
            push!(wallets, account.Pubkey)
            first_unsigned_ro = 1
        else
            insert!(wallets, first_unsigned_ro, account.Pubkey)
        end
    else
        if account.IsSigner
            insert!(wallets, 1, account.Pubkey)
            if first_signed_ro != -1
                first_signed_ro += 1
            end
            if first_unsigned_ro != -1
                first_unsigned_ro += 1
            end
        else
            if first_unsigned_ro < 1
                push!(wallets, account.Pubkey)
                if first_unsigned_ro != -1
                    first_unsigned_ro += 1
                end
            else
                insert!(wallets, first_unsigned_ro, account.Pubkey)
                first_unsigned_ro += 1
            end
        end
    end

    first_ind[1] = first_signed_ro
    first_ind[2] = first_unsigned_ro
end

function process_instructions(instructions::Array{Instruction})
    num_readonly_signed_accounts::UInt8 = 0
    num_readonly_unsigned_accounts::UInt8 = 0
    wallets::Array{String} = []
    wallets_check = Dict()

    first_ind = [1, 1]

    for instruction in instructions
        if !haskey(wallets_check, instruction.ProgramId)
            push!(wallets, instruction.ProgramId)
            wallets_check[instruction.ProgramId] = true
        end
        for account in instruction.Accounts
            if !haskey(wallets_check, account.Pubkey)
                if account.IsSigner && !account.IsWritable
                    # TODO insert into last position that is signed and writable
                    num_readonly_signed_accounts += 1
                elseif !account.IsSigner && !account.IsWritable
                    # TODO insert into last position
                    num_readonly_unsigned_accounts += 1
                end
                insert_wallet(wallets, account, first_ind)
                wallets_check[account.Pubkey] = true
            end
        end
    end

    return wallets, num_readonly_signed_accounts, num_readonly_unsigned_accounts
end

# Create Transaction
function create_transaction(instructions::Array{Instruction})::Transaction

    wallets, num_readonly_signed_accounts, num_readonly_unsigned_accounts = process_instructions(instructions)

    transaction::Transaction = Transaction([], create_message(signatures, wallets, instructions, num_readonly_signed_accounts, num_readonly_unsigned_accounts))

    # TODO insert size checks

    return transaction
end

# Create Message
function create_message(signatures::Array{String}, wallets::Array{String}, Instructions::Array{Instruction}, num_readonly_signed_accounts::UInt8, num_readonly_unsigned_accounts::UInt8)::Message
    # Create Message Header
    required_signatures = size(signatures, 1)
    header::MessageHeader = MessageHeader((UInt8)(required_signatures), num_readonly_signed_accounts, num_readonly_unsigned_accounts)

    # Create Account keys
    AccountKeys::Array{String} = wallets

    # Recent Blockhash
    RecentBlockhash::String = get_latest_blockhash()["value"]["blockhash"]

    message::Message = Message(header, AccountKeys, RecentBlockhash, Instructions)

    return message
end

function pip_send_sol()
    # 1. Set RPC_URL
    url = ""
    # 2. Set secret_key
    secret_key = ""
    # 3. Set receiver pubkeys
    receiver_pubkey = ""
    # 4. Set amount
    amount = 0

    pip_sol.send_sol(url, secret_key, receiver_pubkey, amount)
end