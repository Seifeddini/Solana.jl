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
    Account::Account
    Name::String
    PrivateKey::String
    function Wallet(account::Account, name::String, private_key::String)
        return new(account, name, private_key)
    end
    function Wallet(name::String, Pubkey::String, PrivateKey::String, Balance::UInt64=UInt64(0))
        return new(Account(Pubkey, Vector{UInt8}(undef, 0), false, Balance, System_Programm), name, PrivateKey)
    end
end
export Wallet

struct AccountMeta
    Pubkey::String
    IsSigner::Bool
    IsWritable::Bool
end
export AccountMeta

struct Instruction
    ProgramId::String
    Accounts::Vector{AccountMeta}
    Data::Vector{UInt8}
end
export Instruction

struct CompiledInstructions
    ProgramIdIndex::UInt8
    Accounts::Vector{UInt8}
    Data::Vector{UInt8}
end

struct MessageHeader
    NumRequiredSignatures::UInt8
    NumReadonlySignedAccounts::UInt8
    NumReadonlyUnsignedAccounts::UInt8
end
export MessageHeader

struct Message
    Header::MessageHeader
    AccountKeys::Vector{Vector{UInt8}}
    RecentBlockhash::Vector{UInt8}
    Instructions::Vector{Instruction}
end
export Message

struct Transaction
    Signatures::Vector{Vector{UInt8}}
    Message::Message
end
export Transaction

struct TokenAccount
    AccountAddress::String
    Signature::String
end
export TokenAccount

struct Token
    Address::String
    Program::String
    Decimals::Int
    Signature::String
end
export Token