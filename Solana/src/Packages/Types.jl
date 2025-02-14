System_Programm = "11111111111111111111111111111111";

struct Account
    Pubkey::String
    Data::Vector{UInt8}
    Executable::Bool
    Lamports::UInt64
    Owner::String
    function Account(Pubkey::String, Data::Vector{UInt8}, Executable::Bool, Lamports::UInt64, Owner::String)
        return new(Pubkey, Data, Executable, Lamports, Owner)
    end
end
export Account

struct Wallet
    account::Account
    name::String
    private_key::String
    function Wallet(account::Account, name::String, private_key::String)
        return new(account, name, private_key)
    end
    function Wallet(name::String, Pubkey::String, PrivateKey::String, Balance::UInt64=UInt64(0))
        return new(Account(Pubkey, Vector{UInt8}(undef, 0), false, Balance, System_Programm), name, PrivateKey)
    end
end
export Wallet

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