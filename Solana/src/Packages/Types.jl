SystemProgramm = "11111111111111111111111111111111";

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
        return new(Account(Pubkey, Vector{UInt8}(undef, 0), false, Balance, SystemProgramm), name, PrivateKey)
    end
end
export Wallet

struct AccountMeta
    # COMPRESS: 32-byte Vector
    Pubkey::String
    # COMPRESS: 1-byte
    IsSigner::Bool
    # COMPRESS: 1-byte
    IsWritable::Bool
end
export AccountMeta

struct Instruction
    # COMPRESS: 1 byte index
    # the pubkey of the program that executes this instruction.
    ProgramId::String
    # Involved Transactions
    # COMPRESS: Compact Array of 1 byte
    Accounts::Vector{AccountMeta}
    # COMPRESS: Compact Array
    Data::Vector{UInt8}
end
export Instruction

struct CompiledInstructions
    # Index into the transaction keys array indicating the program account that executes this instruction.
    ProgramIdIndex::UInt8
    # Ordered indices into the transaction keys array indicating which accounts to pass to the program.
    Accounts::Vector{UInt8}
    # The program input data.
    Data::Vector{UInt8}
end
export CompiledInstructions

struct MessageHeader
    # The number of signatures required for this message to be considered
    # valid. The signers of those signatures must match the first
    # `num_required_signatures` of [`Message::account_keys`].
    NumRequiredSignatures::UInt8

    # The last `num_readonly_signed_accounts` of the signed keys are read-only
    # accounts.
    NumReadonlySignedAccounts::UInt8

    # The last `num_readonly_unsigned_accounts` of the unsigned keys are
    # read-only accounts
    NumReadonlyUnsignedAccounts::UInt8
end
export MessageHeader

struct Message
    # Specifies the number of signer and read-only accounts
    # COMPRESS: 3-byte vector
    Header::MessageHeader
    # An array of account addresses required by the instructions on the transaction. Stored in Compact_Array
    # COMPRESS: size * 32-byte vector Compact Array
    AccountKeys::Vector{String}
    # Acts as the timestamp for the transaction. Expires after 150 Blocks
    # COMPRESS: 32-byte vector
    RecentBlockhash::String
    # Array of Instructions to be executed. Stored in Compact_Array. Elements are CompiledInstructions
    # COMPRESS: byte-vector Compact Array
    Instructions::Vector{Instruction}
end
export Message

# Max-Size: 1232 Bytes
# Signatures-Max-Size: 64 Btess each
# Metadata + Accounts in Messages max-size: maximum of 35, 32 bytes each
struct Transaction
    # array of signatures included in Instructions
    # COMPRESS: 64-byte vector Compact Array
    Signatures::Vector{String}
    # List of instructions to be processed
    # COMPRESS: byte-vector
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