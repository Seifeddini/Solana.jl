using Logging

# Set environment variables
ENV["RPC_URL"] = "http://localhost:8899"

# RUN: solana-test-validator --reset 

include("./SolanaServices.jl")
using .SolanaServices


wallet1 = SolanaServices.create_wallet("TestWallet1")

function basic_test()
    @info "----------- Start Basic_Test -----------"

    # TEST create_wallet
    wallet1 = SolanaServices.create_wallet("TestWallet1")
    wallet2 = SolanaServices.create_wallet("TestWallet2")

    @assert wallet1 != Nothing "Wallet 1 is not created"
    @assert wallet2 != Nothing "Wallet 2 is not created"

    @info "Wallets created succsessfully"

    # TEST airdrop_sol
    # TEST get_balance

    @info "----------- Basic Test Passed -----------"
end

basic_test();