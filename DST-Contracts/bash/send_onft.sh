#!/bin/bash

# Send ONFT Cross-Chain
# Usage: ./send_onft.sh <onft_contract> <destination_chain> <recipient> <token_id>
# Example: ./send_onft.sh 0x1234... sepolia 0x5678... 1

set -e

# Check if required parameters are provided
if [ $# -lt 4 ]; then
    echo "Usage: $0 <onft_contract> <destination_chain> <recipient> <token_id>"
    echo "Example: $0 0x1234567890123456789012345678901234567890 sepolia 0x5678901234567890123456789012345678901234 1"
    exit 1
fi

ONFT_CONTRACT=$1
DESTINATION_CHAIN=$2
RECIPIENT=$3
TOKEN_ID=$4

# Set environment variables
export ONFT_CONTRACT=$ONFT_CONTRACT
export DESTINATION_CHAIN=$DESTINATION_CHAIN
export RECIPIENT=$RECIPIENT
export TOKEN_ID=$TOKEN_ID

echo "Sending ONFT cross-chain..."
echo "ONFT Contract: $ONFT_CONTRACT"
echo "Destination Chain: $DESTINATION_CHAIN"
echo "Recipient: $RECIPIENT"
echo "Token ID: $TOKEN_ID"

# Send the ONFT
forge script script/onft/SendONFT.s.sol:SendONFT \
    --rpc-url $DESTINATION_CHAIN \
    --broadcast

echo "Cross-chain NFT transfer initiated!"
echo "Transaction will be processed on the destination chain"
