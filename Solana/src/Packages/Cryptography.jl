using Serialization

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

