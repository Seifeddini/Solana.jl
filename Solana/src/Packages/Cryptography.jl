using Serialization

function base58_encode(data::Vector{UInt8})::String
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = BigInt(0)

    # Convert byte array to BigInt
    for byte in data
        num = num * 256 + byte
    end

    # Encode to Base58
    encoded::String = ""
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

function base58_decode(encoded::String)::Vector{UInt8}
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = BigInt(0)

    # Convert Base58 to BigInt
    for char in encoded
        num = num * 58 + findfirst(alphabet, char) - 1
    end

    # Convert BigInt to byte array
    data::Vector{UInt8} = []
    while num > 0
        num, remainder = divrem(num, 256)
        push!(data, UInt8(remainder))
    end

    # Add leading zeros
    for char in encoded
        if char == '1'
            push!(data, UInt8(0))
        else
            break
        end
    end

    return reverse(data)
end
