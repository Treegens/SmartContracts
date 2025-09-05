#!/bin/bash

# Mint ONFT Tokens
# Usage: ./mint_onft.sh <onft_contract> <recipient> <token_id> [batch]
# Example: ./mint_onft.sh 0x1234... 0x5678... 1
# Example (batch): ./mint_onft.sh 0x1234... 0x5678... 1 batch "1,2,3"

set -e

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    echo "Usage: $0 <onft_contract> <recipient> <token_id> [batch] [token_ids]"
    echo "Example: $0 0x1234567890123456789012345678901234567890 0x5678901234567890123456789012345678901234 1"
    echo "Example (batch): $0 0x1234567890123456789012345678901234567890 0x5678901234567890123456789012345678901234 1 batch \"1,2,3\""
    exit 1
fi

ONFT_CONTRACT=$1
RECIPIENT=$2
TOKEN_ID=$3
BATCH_MINT=${4:-false}
TOKEN_IDS=${5:-""}

# Set environment variables
export ONFT_CONTRACT=$ONFT_CONTRACT
export RECIPIENT=$RECIPIENT
export TOKEN_ID=$TOKEN_ID
export BATCH_MINT=$BATCH_MINT
export TOKEN_IDS=$TOKEN_IDS

echo "Minting ONFT tokens..."
echo "ONFT Contract: $ONFT_CONTRACT"
echo "Recipient: $RECIPIENT"
echo "Token ID: $TOKEN_ID"
echo "Batch Mint: $BATCH_MINT"

if [ "$BATCH_MINT" = "batch" ]; then
    echo "Token IDs: $TOKEN_IDS"
fi

# Mint the ONFT
forge script script/onft/MintONFT.s.sol:MintONFT \
    --rpc-url sepolia \
    --broadcast

echo "Minting completed successfully!"
