#!/bin/bash

# Deploy ONFT721 Contract
# Usage: ./deploy_onft.sh <network> <name> <symbol>
# Example: ./deploy_onft.sh sepolia "MyONFT" "MONFT"

set -e

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    echo "Usage: $0 <network> <name> <symbol>"
    echo "Example: $0 sepolia \"MyONFT\" \"MONFT\""
    exit 1
fi

NETWORK=$1
NAME=$2
SYMBOL=$3

# Set environment variables
export NETWORK=$NETWORK
export ONFT_NAME=$NAME
export ONFT_SYMBOL=$SYMBOL

echo "Deploying MyONFT721 to $NETWORK..."
echo "Name: $NAME"
echo "Symbol: $SYMBOL"

# Deploy the contract
forge script script/onft/DeployMyONFT721.s.sol:DeployMyONFT721 \
    --rpc-url $NETWORK \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

echo "Deployment completed!"
echo "Check the deployments directory for contract addresses and deployment info."
