using Logging

# Set environment variables
ENV["RPC_URL"] = "http://localhost:8899"

# RUN: solana-test-validator --reset 
using Solana

using Test

ENV["RPC_URL"] = "http://localhost:8899"

@testset "Basic Test" begin
    @info "----------- Start Basic_Test -----------"

    # TEST create_wallet
    wallet1 = Solana.create_wallet("TestWallet1")
    wallet2 = Solana.create_wallet("TestWallet2")

    @test wallet1 != Nothing
    @test wallet2 != Nothing

    @info "Wallets created succsessfully"

    # TEST airdrop_sol
    Solana.airdrop_sol(wallet1.pubkey, 1_000_000_000)
    Solana.airdrop_sol(wallet2.pubkey, 2_500_000_000)
    # TEST get_balance
    @test Solana.get_balance(wallet1.pubkey) == 1_000_000_000
    @test Solana.get_balance(wallet2.pubkey) == 2_500_000_000

    @info "----------- Basic Test Passed -----------"
end