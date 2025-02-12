using Logging

# Set environment variables
ENV["RPC_URL"] = "http://localhost:8899"

# RUN: solana-test-validator --reset 

include("./SolanaServices.jl")
using .SolanaServices

function basic_test()
    @info "Start Basic_Test"

    # TEST create_wallet
    wallet1 = SolanaServices.create_wallet("TestWallet1")
    wallet2 = SolanaServices.create_wallet("TestWallet2")

    # TEST airdrop_sol
    # TEST get_balance
end

basic_test();