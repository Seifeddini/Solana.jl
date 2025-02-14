
struct AccountMeta
    pubkey::Vector{UInt8}
    is_signer::Bool
    is_writable::Bool
end
export AccountMeta

struct Instruction
    program_id::Vector{UInt8}
    accounts::Vector{AccountMeta}
    data::Vector{UInt8}
end
export Instruction

struct MessageHeader
    num_required_signatures::UInt8
    num_readonly_signed_accounts::UInt8
    num_readonly_unsigned_accounts::UInt8
end
export MessageHeader

struct Message
    header::MessageHeader
    account_keys::Vector{Vector{UInt8}}
    recent_blockhash::Vector{UInt8}
    instructions::Vector{Instruction}
end
export Message

struct Transaction
    signatures::Vector{Vector{UInt8}}
    message::Message
end
export Transaction

struct Wallet
    name::String
    pubkey::String
    secretkey::String
end
export Wallet

struct TokenAccount
    account_address::String
    signature::String
end
export TokenAccount

struct Token
    address::String
    program::String
    decimals::Int
    signature::String
end
export Token