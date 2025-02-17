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

function to_compact_array(arr::Array{T}, ::Type{U}) where {T,U}
    io = IOBuffer()
    write(io, CompactU16(UInt16(length(arr))))

    write(io, serialize(arr, U))
    return take!(io)
end

function serialize(arr::Array{T}, ::Type{U}) where {T,U}
    buffer = IOBuffer()

    for elem in arr
        if elem isa AbstractArray
            serialized_elem = serialize(elem, U)
            write(buffer, serialized_elem)
        else
            write(buffer, convert(U, elem))
        end
    end

    return take!(buffer)
end

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

function serialize_struct(s::T, ::Type{U}) where {T,U}
    buffer = IOBuffer()
    fieldnames = fieldnames(T)
    for field in fieldnames
        value = getfield(s, field)
        if isstruct(value)
            serialized_value = serialize_struct(value, U)
            write(buffer, serialized_value)
        elseif value isa AbstractArray
            serialized_value = serialize(value, U)
            write(buffer, serialized_value)
        else
            serialize(buffer, convert(U, value))
        end
    end
    return take!(buffer)
end
function isstruct(x)
    return x isa DataType && isstructtype(x)
end

function isstructtype(T::DataType)
    return T <: AbstractDict || T <: AbstractArray || T <: Tuple || T <: NamedTuple || T <: Struct
end
