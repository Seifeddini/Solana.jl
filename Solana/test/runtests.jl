using Logging

# Set environment variables
ENV["RPC_URL"] = "http://localhost:8899"

# RUN: solana-test-validator --reset 
using Solana

using Test, HTTP, Serialization, Nettle

using Random

# Generate a random 32-byte string
random_bytes = rand(UInt8, 32)

# Encode the random bytes to Base58
random_base58 = Solana.base58_encode(random_bytes)

# Print the random Base58 string
Nettle.ed25519_sign(random_base58, message)


@testset "CompactU16 and Compact Array Tests" begin
    @testset "CompactU16 Encoding/Decoding" begin
        test_values = [0, 127, 128, 255, 16383, 16384, 65535]
        for value in test_values
            compact = CompactU16(UInt16(value))
            io = IOBuffer()
            serialize(io, compact)
            encoded = take!(io)

            io = IOBuffer(encoded)
            decoded = deserialize(io)

            @test decoded.value == value
        end
    end
end

@testset "Base58 Decode" begin
    @testset "Base58 Decoding" begin
        test_cases = [
            ("", UInt8[]),
            ("1", [0x00]),
            ("2", [0x01]), #                                         2b     02    7f    dd    48    36    ed    8a    17    73    06    74   8a     06    05    49    d7    71    5d   80    df    83     e2    3e    48    53    df    f0    05    b1    95    75    31    16   03
            ("5HueCGU8rMjxEXxiPuD5BDuZZ7s5g9G2UJm2zG1Jwq3h5h9t", [0x2b, 0x02, 0x7f, 0xdd, 0x48, 0x36, 0xed, 0x8a, 0x17, 0x73, 0x06, 0x74, 0x8a, 0x06, 0x05, 0x49, 0xd7, 0x71, 0x5d, 0x80, 0xdf, 0x83, 0xe2, 0x3e, 0x48, 0x53, 0xdf, 0xf0, 0x05, 0xb1, 0x95, 0x75, 0x31, 0x16, 0x03])
        ]
        for (encoded, expected) in test_cases
            decoded = Solana.base58_decode(encoded)
            @test decoded == expected
        end
    end

    @testset "Base58 Encoding" begin
        test_cases = [
            (UInt8[], ""),
            ([0x00], "1"),
            ([0x01], "2"),
            ([0x01, 0x10, 0xc4, 0x4f, 0xc3, 0x90, 0x18, 0xcd, 0x4f, 0xb9, 0x75, 0x07, 0xf0, 0x0a, 0xae, 0xc1, 0xa4], "agadsfgafdageaofkagasd")
        ]
        for (encoded, expected) in test_cases
            decoded = Solana.base58_encode(encoded)
            @test decoded == expected
        end
    end
end

@testset failfast = true "transfer_sol" begin
    # TODO Create Mock-Wallets
    wallet_A::Wallet = Solana.create_wallet("TestWalletA")
    wallet_B::Wallet = Solana.create_wallet("TestWalletB")
    wallet_C::Wallet = Solana.create_wallet("TestWalletC")
    # TODO Fund Mock-Wallets
    wait(Solana.airdrop_sol_async(wallet_A.Account.Pubkey, 1_000_000_000, "finalized"))
    wait(Solana.airdrop_sol_async(wallet_B.Account.Pubkey, 1_000_000_000, "finalized"))

    instructions::Array{Instruction} = []
    amount::UInt64 = UInt64(1_000_000)

    # fill Instructions

    instruction_id_1 = 2
    data_buffer_1 = IOBuffer()
    write(data_buffer_1, UInt32(instruction_id_1))
    write(data_buffer_1, UInt64(amount))

    instruction_id_2 = 3
    data_buffer_2 = IOBuffer()
    write(data_buffer_2, UInt32(instruction_id_2))
    write(data_buffer_2, UInt64(amount))

    data_1 = take!(data_buffer_1)
    data_2 = take!(data_buffer_2)

    push!(instructions, Instruction(Solana.solana_programms["system"], [AccountMeta(wallet_A.Account.Pubkey, true, true), AccountMeta(wallet_B.Account.Pubkey, false, true)], data_1))
    push!(instructions, Instruction(Solana.solana_programms["system"], [AccountMeta(wallet_B.Account.Pubkey, true, true), AccountMeta(wallet_C.Account.Pubkey, false, true)], data_2))

    # TODO create Transaction and test
    wallet_A_sig = Solana.base58_encode(Solana.base58_decode(wallet_A.PrivateKey))

    transaction::Transaction = Solana.create_transaction([wallet_A.PrivateKey * wallet_A.Account.Pubkey, wallet_B.PrivateKey * wallet_B.Account.Pubkey], instructions)

    @testset failfast = true "create transaction" begin
        @test transaction !== nothing
        @testset "Signatures" begin
            @test size(transaction.Signatures, 1) == 2
            @test transaction.Signatures[1] === wallet_A.PrivateKey * wallet_A.Account.Pubkey
            @test transaction.Signatures[2] === wallet_B.PrivateKey * wallet_B.Account.Pubkey
        end
        @testset "Message" begin
            @testset "Header" begin
                @test transaction.Message.Header.NumRequiredSignatures == UInt8(2)
                @test transaction.Message.Header.NumReadonlySignedAccounts == UInt8(0)
                @test transaction.Message.Header.NumReadonlyUnsignedAccounts == UInt8(0)
            end
            @testset "AccountKeys" begin
                @test size(transaction.Message.AccountKeys, 1) == 4
                @test transaction.Message.AccountKeys[1] == wallet_A.Account.Pubkey
                @test transaction.Message.AccountKeys[2] == wallet_B.Account.Pubkey
                @test transaction.Message.AccountKeys[3] == wallet_C.Account.Pubkey
            end
        end
    end

    transaction_string = Solana.serialize_transaction(transaction)
    transaction_bytes = Solana.base58_decode(transaction_string)

    signatures_size = Solana.base58_decode([transaction_bytes[1]])
    first_signature = Solana.base58_decode(transaction_bytes[2:65])
    @testset failfast = true "deserialize transaction" begin
        @test signatures_size !== nothing
        @test Int64(signatures_size) == 2
        @test first_signature !== nothing
        @test first_signature == wallet_A.PrivateKey * wallet_A.Account.Pubkey
        #@test length(join([wallet_A.PrivateKey, wallet_A.Account.Pubkey], "")) == 64
        #@test length(transaction_bytes[1:64]) == 64
        #@test Solana.base58_encode(transaction_bytes[1:64]) == join([wallet_A.PrivateKey, wallet_A.Account.Pubkey], "")
    end

    # # TODO Transfer SOL between Mock-Wallets
    # @info "Starting Transaction..."
    # tr = Solana.transfer_sol_async(wallet_A, wallet_B.Account.Pubkey, UInt64(1_000_000))
    # @info "Finished Transaction..."
    # sleep(25)
    # # TODO Verify Transfer
    # @test tr !== nothing
    # @test Solana.get_balance(wallet_A.Account.Pubkey) == 999_000_000
    # @test Solana.get_balance(wallet_B.Account.Pubkey) == 1_000_000
end


@testset failfast = true "Basic Test" begin
    @info "----------- Start Basic_Test -----------"

    # TEST create_wallet
    wallet1::Wallet = Solana.create_wallet("TestWallet1")
    wallet2::Wallet = Solana.create_wallet("TestWallet2")

    @test wallet1 !== nothing
    @test wallet2 !== nothing
    @test wallet1.account.Pubkey !== wallet2.account.Pubkey

    @info "Wallets created successfully"

    # TEST airdrop_sol
    airdrop_amount1 = 1_000_000_000
    airdrop_amount2 = 2_500_000_000
    tr_w1 = Solana.airdrop_sol_async(wallet1.account.Pubkey, airdrop_amount1, "finalized")
    tr_w2 = Solana.airdrop_sol_async(wallet2.account.Pubkey, airdrop_amount2, "finalized")

    @test tr_w1 !== nothing
    @test tr_w2 !== nothing

    tr_w1 = wait(tr_w1)
    tr_w2 = wait(tr_w2)

    @info "Airdrop transactions completed"

    # TEST get_balance
    balance1 = Solana.get_balance(wallet1.account.Pubkey)
    balance2 = Solana.get_balance(wallet2.account.Pubkey)

    @test balance1 == airdrop_amount1
    @test balance2 == airdrop_amount2

    @info "Balances verified"

    @info "----------- Basic Test Passed -----------"
end

@testset failfast = true "Token Test" begin
    @info "----------- Start Token_Test -----------"
    # Test creating Token_Test
    token::Token = Solana.create_token()

    @test token isa Token
    # Test creating Token_Wallet
    token_wallet = Solana.create_token_account(token.address)

    @test token_wallet !== nothing
    # Test minting tokens

    mint_amount::Int = 1_000_000_000
    minted = Solana.mint_token(token.address, mint_amount)

    @test minted !== nothing

    #minted = wait(minted)

    @test minted isa String

    @test Solana.check_token_balance(token.address) == mint_amount

    @info "----------- Token Test Passed -----------"
end

