#!/bin/bash

# LayerZero Peer Setup Script
# This script sets up peer relationships between Base Sepolia (BaseMgroOapp) and OP Sepolia (CeloMgroOapp)

set -e

source .env

# Check if required environment variables are set
if [ -z "$TESTNET_PRIVATE_KEY" ]; then
    echo "Error: TESTNET_PRIVATE_KEY environment variable is not set"
    exit 1
fi

# Contract addresses
BASE_MGRO_OAPP="0xf45dF8589D9C646f12D312316fAeA5574b6e6460"  # Base Sepolia
CELO_MGRO_OAPP="0x64604916fC579BA90f01db623E5881C111430c89"  # OP Sepolia

# Chain IDs
OP_SEPOLIA_CHAIN_ID=11155420
BASE_SEPOLIA_CHAIN_ID=84532

# EIDs from ChainConfig
OP_SEPOLIA_EID=40232
BASE_SEPOLIA_EID=40245

echo "=== LayerZero Peer Setup ==="
echo "CeloMgroOapp (OP Sepolia): $CELO_MGRO_OAPP"
echo "BaseMgroOapp (Base Sepolia): $BASE_MGRO_OAPP"
echo "OP Sepolia EID: $OP_SEPOLIA_EID"
echo "Base Sepolia EID: $BASE_SEPOLIA_EID"
echo ""

# Set default RPC URLs if not provided
if [ -z "$OP_SEPOLIA_RPC_URL" ]; then
    OP_SEPOLIA_RPC_URL="https://sepolia.optimism.io"
fi

if [ -z "$BASE_SEPOLIA_RPC_URL" ]; then
    BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
fi

# Function to setup peer on OP Sepolia
setup_op_sepolia() {
    echo "=== Setting up CeloMgroOapp on OP Sepolia ==="
    echo "Setting peer to Base Sepolia (EID: $BASE_SEPOLIA_EID)"
    
    cd /home/kaushal/treegen/smartcontracts/DST-Contracts
    
    forge script script/SetPeer.s.sol:SetPeer \
        --rpc-url $OP_SEPOLIA_RPC_URL \
        --private-key $TESTNET_PRIVATE_KEY \
        --broadcast \
        -vvv \
        --sig "run(address,uint32,address)" \
        $CELO_MGRO_OAPP \
        $BASE_SEPOLIA_EID \
        $BASE_MGRO_OAPP
    
    echo "✅ CeloMgroOapp peer set to Base Sepolia"
}

# Function to setup peer on Base Sepolia
setup_base_sepolia() {
    echo "=== Setting up BaseMgroOapp on Base Sepolia ==="
    echo "Setting peer to OP Sepolia (EID: $OP_SEPOLIA_EID)"
    
    cd /home/kaushal/treegen/smartcontracts/DST-Contracts
    
    forge script script/SetPeer.s.sol:SetPeer \
        --rpc-url $BASE_SEPOLIA_RPC_URL \
        --private-key $TESTNET_PRIVATE_KEY \
        --broadcast \
        -vvv \
        --sig "run(address,uint32,address)" \
        $BASE_MGRO_OAPP \
        $OP_SEPOLIA_EID \
        $CELO_MGRO_OAPP
    
    echo "✅ BaseMgroOapp peer set to OP Sepolia"
}

# Function to verify peer setup
verify_peers() {
    echo "=== Verifying Peer Setup ==="
    
    # Check OP Sepolia peer
    echo "Checking CeloMgroOapp peer on OP Sepolia..."
    OP_PEER=$(cast call --rpc-url $OP_SEPOLIA_RPC_URL $CELO_MGRO_OAPP "peers(uint32)(bytes32)" $BASE_SEPOLIA_EID)
    echo "OP Sepolia peer for Base Sepolia EID: $OP_PEER"
    
    # Check Base Sepolia peer
    echo "Checking BaseMgroOapp peer on Base Sepolia..."
    BASE_PEER=$(cast call --rpc-url $BASE_SEPOLIA_RPC_URL $BASE_MGRO_OAPP "peers(uint32)(bytes32)" $OP_SEPOLIA_EID)
    echo "Base Sepolia peer for OP Sepolia EID: $BASE_PEER"
}

# Main execution
echo "Starting LayerZero peer setup..."

# Setup peers
setup_op_sepolia
echo ""
setup_base_sepolia
echo ""

# Verify setup
verify_peers

echo ""
echo "🎉 LayerZero peer setup complete!"
echo "CeloMgroOapp (OP Sepolia) can now receive messages from Base Sepolia"
echo "BaseMgroOapp (Base Sepolia) can now receive messages from OP Sepolia"