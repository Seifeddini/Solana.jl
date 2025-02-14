
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

struct CompactU16
    value::UInt16
end

function Base.show(io::IO, cu::CompactU16)
    print(io, "CompactU16(", cu.value, ")")
end

function Base.serialize(s::AbstractSerializer, cu::CompactU16)
    rem_val = cu.value
    while true
        elem = UInt8(rem_val & 0x7f)
        rem_val >>= 7
        if rem_val == 0
            write(s, elem)
            break
        else
            write(s, elem | 0x80)
        end
    end
end

function Base.deserialize(s::AbstractSerializer, ::Type{CompactU16})
    val = UInt16(0)
    for i in 0:2
        elem = read(s, UInt8)
        val |= UInt16(elem & 0x7f) << (i * 7)
        if (elem & 0x80) == 0
            return CompactU16(val)
        end
    end
    throw(ErrorException("Invalid CompactU16 encoding"))
end

function encode_compact_u16(value::UInt16)
    io = IOBuffer()
    serialize(io, CompactU16(value))
    return take!(io)
end

function decode_compact_u16(bytes::Vector{UInt8})
    io = IOBuffer(bytes)
    return deserialize(io, CompactU16).value
end

function to_compact_array(arr::Array{T}) where {Task}
    # Create an IOBuffer to write our compact array
    io = IOBuffer()

    # Encode and write the length of the array using CompactU16
    serialize(io, CompactU16(UInt16(length(arr))))

    # Serialize each element of the array
    for elem in arr
        serialize(io, elem)
    end

    # Return the compact array as a Vector{UInt8}
    return take!(io)
end

function from_compact_array(bytes::Vector{UInt8}, ::Type{T}) where {T}
    io = IOBuffer(bytes)

    # Deserialize the length
    length = deserialize(io, CompactU16).value

    # Deserialize each element
    result = Vector{T}(undef, length)
    for i in 1:length
        result[i] = deserialize(io, T)
    end

    return result
end