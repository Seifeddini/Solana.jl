using Logging

# Set environment variables
ENV["RPC_URL"] = "http://localhost:8899"

# RUN: solana-test-validator --reset 
using Solana

using Test, HTTP, Serialization

@testset failfast = true "transfer_sol" begin
    # TODO Create Mock-Wallets
    wallet_A::Wallet = Solana.create_wallet("TestWalletA")
    wallet_B::Wallet = Solana.create_wallet("TestWalletB")
    # TODO Fund Mock-Wallets
    wait(Solana.airdrop_sol_async(wallet_A.Account.Pubkey, 1_000_000_000, "finalized"))

    instructions::Array{Instruction} = []
    num_readonly_signed_accounts::UInt8 = UInt8(0)
    num_readonly_unsigned_accounts::UInt8 = UInt8(0)
    amount::UInt64 = UInt64(1_000_000)

    # fill Instructions

    instruction_id = 2
    data_buffer = IOBuffer()
    write(data_buffer, UInt32(instruction_id))
    write(data_buffer, UInt64(amount))

    data = take!(data_buffer)

    push!(instructions, Instruction(Solana.solana_programms["system"], [AccountMeta(wallet_A.Account.Pubkey, true, true), AccountMeta(wallet_B.Account.Pubkey, false, true)], data))

    # TODO create Transaction and test
    transaction::Transaction = Solana.create_transaction([wallet_A.PrivateKey], instructions)

    @testset failfast = true "create transaction" begin
        @test transaction !== nothing
        @test size(transaction.Signatures, 1) == 1
        @test transaction.Signatures[1] === wallet_A.PrivateKey
    end

    transaction_string = serialize(transaction)
    transaction_bytes = base58_decode(transaction_string)
    # TODO test for correctness

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

@testset "Base58 Decode Tests" begin
    @testset "Base58 Decoding" begin
        test_cases = [
            ("", UInt8[]),
            ("1", [0x00]),
            ("2", [0x01]),
            ("5HueCGU8rMjxEXxiPuD5BDuZZ7s5g9G2UJm2zG1Jwq3h5h9t", [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        ]
        for (encoded, expected) in test_cases
            decoded = base58_decode(encoded)
            @test decoded == expected
        end
    end
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

