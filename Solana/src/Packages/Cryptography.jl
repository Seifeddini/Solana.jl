using Serialization, PyCall

@pyimport nacl.signing as signing
@pyimport base58

function base58_encode(data::Vector{UInt8})::String
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = BigInt(0)
    leading_zeros = 0

    # Count leading zero bytes
    for byte in data
        if byte == 0
            leading_zeros += 1
        else
            break
        end
    end

    # Convert byte array to BigInt
    for byte in data
        num = num * 256 + byte
    end

    # Pre-allocate the string (approximate size)
    encoded = IOBuffer(sizehint=length(data) * 138 ÷ 100 + 1)

    # Encode to Base58
    while num > 0
        num, remainder = divrem(num, 58)
        write(encoded, alphabet[remainder+1])
    end

    # Add leading '1's for each leading zero byte in the input
    for _ in 1:leading_zeros
        write(encoded, '1')
    end

    return String(reverse(take!(encoded)))
end


# Base58 decoding implementation in Julia
function base58_decode(encoded::String)
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = BigInt(0)
    leading_zeros = 0

    # Count leading '1's and remove them
    while startswith(encoded, '1')
        leading_zeros += 1
        encoded = encoded[2:end]
    end

    # Convert Base58 string to BigInt
    for char in encoded
        index = findfirst(c -> c == char, alphabet)
        if index === nothing
            throw(ArgumentError("Invalid character in Base58 string: $char"))
        end
        num = num * 58 + (index - 1)  # Subtract 1 because Julia uses 1-based indexing
    end

    # Convert BigInt back to byte array
    decoded = UInt8[]
    while num > 0
        push!(decoded, UInt8(mod(num, 256)))
        num = div(num, 256)
    end

    # Add leading zero bytes
    append!(decoded, zeros(UInt8, leading_zeros))

    # Reverse to get the original byte order
    return reverse(decoded)
end

# Generate keypair
signer = signing.SigningKey.generate()
verify_key = signer.verify_key

# Convert to Solana format
secret_key = base58.b58encode(signer.encode() + verify_key.encode())
public_key = base58.b58encode(verify_key.encode())

println("Public: ", public_key)
println("Secret: ", secret_key)

@pyimport solana.rpc.async_api as async_api
@pyimport solana.transaction as transaction

function sign_transaction(instructions::Vector{Dict}, signer::PyObject)
    client = async_api.AsyncClient("https://api.devnet.solana.com")
    blockhash = pycall(client.get_latest_blockhash, PyObject)

    txn = transaction.Transaction().add([
        transaction.TransactionInstruction(
            keys=[
                transaction.AccountMeta(py"instruction['accounts'][0]['pubkey']",
                    py"instruction['accounts'][0]['is_signer']",
                    py"instruction['accounts'][0]['is_writable']"),
                transaction.AccountMeta(py"instruction['accounts'][1]['pubkey']",
                    false, true)
            ],
            program_id=py"instruction['program_id']",
            data=py"base64.b64decode(instruction['data'])"
        ) for instruction in instructions
    ])

    txn.sign(signer)
    return txn
end


