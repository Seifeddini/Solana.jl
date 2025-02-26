from solana.rpc.async_api import AsyncClient
from solana.transaction import Transaction
from solana.system_program import TransferParams, transfer

async def send_sol(url: str, secret_key: str, receiver: str, amount: int):
    client = AsyncClient(url)
    
    sender = Keypair.from_secret_key(bytes.fromhex(secret_key))
    receiver = PublicKey(receiver)
    
    transfer_ix = transfer(TransferParams(
        from_pubkey=sender.pubkey(),
        to_pubkey=receiver,
        lamports=amount  # 1 SOL
    ))
    
    txn = Transaction().add(transfer_ix)
    txn.sign(sender)
    
    serialized_txn = txn.serialize()
    response = await client.send_raw_transaction(serialized_txn)
    print(f"Transaction Signature: {response.value}")
    return response.value
