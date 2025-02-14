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
    for elem in arr
        serialize(io, elem)
    end
    return take!(io)
end

function from_compact_array(bytes::Vector{UInt8}, ::Type{T}) where {T}
    io = IOBuffer(bytes)
    length = read(io, CompactU16).value
    result = Vector{T}(undef, length)
    for i in 1:length
        result[i] = deserialize(io)
    end
    return result
end
