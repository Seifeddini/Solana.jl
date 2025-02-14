
function base58_encode(data::Vector{UInt8})
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = BigInt(0)

    # Convert byte array to BigInt
    for byte in data
        num = num * 256 + byte
    end

    # Encode to Base58
    encoded = ""
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