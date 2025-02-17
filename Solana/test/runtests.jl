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
    # TODO Transfer SOL between Mock-Wallets
    @info "Starting Transaction..."
    tr = Solana.transfer_sol_async(wallet_A, wallet_B.Account.Pubkey, UInt64(1_000_000))
    @info "Finished Transaction..."
    sleep(25)
    # TODO Verify Transfer
    @test tr !== nothing
    @test Solana.get_balance(wallet_A.Account.Pubkey) == 999_000_000
    @test Solana.get_balance(wallet_B.Account.Pubkey) == 1_000_000
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

    @testset "Compact Array - Integers" begin
        int_arrays = [
            Int[],
            [1],
            [1, 2, 3, 4, 5],
            [0, 127, 128, 255, 16383, 16384, 65535]
        ]
        for arr in int_arrays
            compact = Solana.to_compact_array(arr)
            decoded = Solana.from_compact_array(compact, Int)
            @test decoded == arr
        end
    end

    @testset "Compact Array - Strings" begin
        string_arrays = [
            String[],
            [""],
            ["hello"],
            ["hello", "world", "julia"],
            ["a", "bb", "ccc", "dddd", "eeeee"]
        ]
        for arr in string_arrays
            compact = Solana.to_compact_array(arr)
            decoded = Solana.from_compact_array(compact, String)
            @test decoded == arr
        end
    end

    @testset "Compact Array - Custom Struct" begin
        struct Point
            x::Float64
            y::Float64
        end

        point_arrays = [
            Point[],
            [Point(1.0, 2.0)],
            [Point(1.0, 2.0), Point(3.0, 4.0), Point(5.0, 6.0)],
            [Point(0.0, 0.0), Point(-1.5, 2.5), Point(3.14, -2.718)]
        ]
        for arr in point_arrays
            compact = Solana.to_compact_array(arr)
            decoded = Solana.from_compact_array(compact, Point)
            @test decoded == arr
        end
    end

    @testset "Error Handling" begin
        @test_throws ErrorException Solana.from_compact_array([0xFF, 0xFF, 0xFF], Int)
        @test_throws EOFError Solana.from_compact_array([0x01], Int)
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

