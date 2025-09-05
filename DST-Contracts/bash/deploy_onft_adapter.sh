#!/bin/bash

# Deploy ONFT721Adapter Contract
# Usage: ./deploy_onft_adapter.sh <network> <token_address>
# Example: ./deploy_onft_adapter.sh sepolia 0x1234567890123456789012345678901234567890

set -e

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <network> <token_address>"
    echo "Example: $0 sepolia 0x1234567890123456789012345678901234567890"
    exit 1
fi

NETWORK=$1
TOKEN_ADDRESS=$2

# Set environment variables
export NETWORK=$NETWORK
export TOKEN_ADDRESS=$TOKEN_ADDRESS

echo "Deploying MyONFT721Adapter to $NETWORK..."
echo "Token Address: $TOKEN_ADDRESS"

# Deploy the contract
forge script script/onft/DeployMyONFT721Adapter.s.sol:DeployMyONFT721Adapter \
    --rpc-url $NETWORK \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

echo "Deployment completed!"
echo "Check the deployments directory for contract addresses and deployment info."
