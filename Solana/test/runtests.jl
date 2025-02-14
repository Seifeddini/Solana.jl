using Logging

# Set environment variables
ENV["RPC_URL"] = "http://localhost:8899"

# RUN: solana-test-validator --reset 
using Solana

using Test, HTTP

@testset "Basic Test" begin
    @info "----------- Start Basic_Test -----------"

    # TEST create_wallet
    wallet1::Wallet = Solana.create_wallet("TestWallet1")
    wallet2::Wallet = Solana.create_wallet("TestWallet2")

    @test wallet1 !== nothing
    @test wallet2 !== nothing
    @test wallet1.pubkey !== wallet2.pubkey

    @info "Wallets created successfully"

    # TEST airdrop_sol
    airdrop_amount1 = 1_000_000_000
    airdrop_amount2 = 2_500_000_000
    tr_w1 = Solana.airdrop_sol_async(wallet1.pubkey, airdrop_amount1, "finalized")
    tr_w2 = Solana.airdrop_sol_async(wallet2.pubkey, airdrop_amount2, "finalized")

    @test tr_w1 !== nothing
    @test tr_w2 !== nothing

    tr_w1 = wait(tr_w1)
    tr_w2 = wait(tr_w2)

    @info "Airdrop transactions completed"

    # TEST get_balance
    balance1 = Solana.get_balance(wallet1.pubkey)
    balance2 = Solana.get_balance(wallet2.pubkey)

    @test balance1 == airdrop_amount1
    @test balance2 == airdrop_amount2

    @info "Balances verified"

    @info "----------- Basic Test Passed -----------"
end

@testset "Token Test" begin
    @info "----------- Start Token_Test -----------"
    # Test creating Token_Test
    token::Token = Solana.create_token()

    @test token isa Token
    # Test creating Token_Wallet
    token_wallet = Solana.create_token_account(token.address)

    @test token_wallet !== nothing
    # Test minting tokens
end
