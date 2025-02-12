using Logging

# Set environment variables
ENV["RPC_URL"] = "http://localhost:8899"

# RUN: solana-test-validator --reset 
using Solana

using Test

@testset "Basic Test" begin
    @info "----------- Start Basic_Test -----------"

    # TEST create_wallet
    wallet1 = Solana.create_wallet("TestWallet1")
    wallet2 = Solana.create_wallet("TestWallet2")

    @test wallet1 !== nothing
    @test wallet2 !== nothing
    @test wallet1.pubkey !== wallet2.pubkey

    @info "Wallets created successfully"

    # TEST airdrop_sol
    airdrop_amount1 = 1_000_000_000
    airdrop_amount2 = 2_500_000_000
    tr_w1 = Solana.airdrop_sol(wallet1.pubkey, airdrop_amount1)
    tr_w2 = Solana.airdrop_sol(wallet2.pubkey, airdrop_amount2)

    @test tr_w1 !== nothing
    @test tr_w2 !== nothing

    @info "Airdrop transactions completed"

    sleep(15)  # Wait for transactions to be processed

    # TEST get_balance
    balance1 = Solana.get_balance(wallet1.pubkey)
    balance2 = Solana.get_balance(wallet2.pubkey)

    @test balance1 == airdrop_amount1
    @test balance2 == airdrop_amount2

    @info "Balances verified"
    @info "----------- Basic Test Passed -----------"
end
