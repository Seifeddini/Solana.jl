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
    # string
    pubkey::Vector{UInt8}
    # bool
    is_signer::UInt8
    # bool
    is_writable::UInt8
end
export AccountMeta

struct Instruction
    program_id::String
    accounts::Vector{AccountMeta}
    data::Vector{UInt8}
end
export Instruction

struct CompiledInstructions
    # Index into the transaction keys array indicating the program account that executes this instruction.
    program_id_index::UInt8
    # Ordered indices into the transaction keys array indicating which accounts to pass to the program.
    accounts::Vector{UInt8}
    # The program input data.
    data::Vector{UInt8}
end

struct MessageHeader
    # The number of signatures required for this message to be considered
    # valid. The signers of those signatures must match the first
    # `num_required_signatures` of [`Message::account_keys`].
    num_required_signatures::UInt8

    # The last `num_readonly_signed_accounts` of the signed keys are read-only
    # accounts.
    num_readonly_signed_accounts::UInt8

    # The last `num_readonly_unsigned_accounts` of the unsigned keys are
    # read-only accounts
    num_readonly_unsigned_accounts::UInt8
end
export MessageHeader

struct Message
    # Specifies the number of signer and read-only accounts
    header::Vector{UInt8}
    # An array of account addresses required by the instructions on the transaction. Stored in Compact_Array
    account_keys::Vector{UInt8}
    # Acts as the timestamp for the transaction. Expires after 150 Blocks
    recent_blockhash::Vector{UInt8}
    # Array of Instructions to be executed. Stored in Compact_Array. Elements are CompiledInstructions
    instructions::Vector{UInt8}
end
export Message

# Max-Size: 1232 Bytes
# Signatures-Max-Size: 64 Btess each
# Metadata + Accounts in Messages max-size: maximum of 35, 32 bytes each
struct Transaction
    # array of signatures included in Instructions
    signatures::Vector{UInt8}
    # List of instructions to be processed
    message::Vector{UInt8}
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