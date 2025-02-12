module SolanaTypes

struct AccountMeta
    pubkey::Vector{UInt8}
    is_signer::Bool
    is_writable::Bool
end

struct Instruction
    program_id::Vector{UInt8}
    accounts::Vector{AccountMeta}
    data::Vector{UInt8}
end

struct MessageHeader
    num_required_signatures::UInt8
    num_readonly_signed_accounts::UInt8
    num_readonly_unsigned_accounts::UInt8
end

struct Message
    header::MessageHeader
    account_keys::Vector{Vector{UInt8}}
    recent_blockhash::Vector{UInt8}
    instructions::Vector{Instruction}
end

struct Transaction
    signatures::Vector{Vector{UInt8}}
    message::Message
end

struct Wallet
    name::String
    pubkey::String
    secretkey::String
end

#struct Wallet


export Instruction, AccountMeta, Transaction, Message, MessageHeader, Wallet

end