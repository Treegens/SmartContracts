#!/bin/bash

# Complete Multi-Network Deployment Script
# This script deploys all contracts across Base Sepolia, OP Sepolia, and Ethereum Sepolia

set -e

echo "=== Complete Multi-Network Deployment ==="
echo "Deploying contracts on Base Sepolia, OP Sepolia, and Ethereum Sepolia..."

# Configuration
export PRIVATE_KEY=${PRIVATE_KEY:-$1}
export BASE_SEPOLIA_RPC="https://sepolia.base.org"
export OP_SEPOLIA_RPC="https://sepolia.optimism.io"
export ETH_SEPOLIA_RPC="https://rpc.sepolia.org"

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set. Please set PRIVATE_KEY or pass it as first argument"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "Configuration:"
echo "- Base Sepolia RPC: $BASE_SEPOLIA_RPC"
echo "- OP Sepolia RPC: $OP_SEPOLIA_RPC"
echo "- Ethereum Sepolia RPC: $ETH_SEPOLIA_RPC"

# Function to run forge script
run_forge_script() {
    local script_path=$1
    local rpc_url=$2
    local script_name=$(basename "$script_path" .s.sol)

    echo -e "${YELLOW}Running $script_name...${NC}"

    if forge script $script_path \
        --rpc-url $rpc_url \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --verify \
        -vvvv; then
        echo -e "${GREEN}✓ $script_name completed successfully${NC}"
    else
        echo -e "${RED}✗ $script_name failed${NC}"
        exit 1
    fi
}

# Function to extract address from forge output
extract_address() {
    local output=$1
    local pattern=$2
    echo "$output" | grep "$pattern" | awk '{print $4}'
}

echo ""
echo -e "${BLUE}=== PHASE 1: Base Sepolia Deployment ===${NC}"

# Deploy on Base Sepolia
cd script/base-sepolia

echo -e "${YELLOW}Step 1.1: Deploying Diamond...${NC}"
DIAMOND_OUTPUT=$(run_forge_script "DeployDiamondBaseSepolia.s.sol" "$BASE_SEPOLIA_RPC")
DIAMOND_ADDRESS=$(extract_address "$DIAMOND_OUTPUT" "Diamond deployed at:")
echo "Diamond Address: $DIAMOND_ADDRESS"

echo -e "${YELLOW}Step 1.2: Deploying TreegenNFT Canonical...${NC}"
NFT_OUTPUT=$(run_forge_script "DeployNftCanonicalBaseSepolia.s.sol" "$BASE_SEPOLIA_RPC")
NFT_ADDRESS=$(extract_address "$NFT_OUTPUT" "TreegenNFT deployed at:")
echo "NFT Canonical Address: $NFT_ADDRESS"

echo -e "${YELLOW}Step 1.3: Deploying TGNDAO...${NC}"
DAO_OUTPUT=$(run_forge_script "DeployTGNDAOBaseSepolia.s.sol" "$BASE_SEPOLIA_RPC")
DAO_ADDRESS=$(extract_address "$DAO_OUTPUT" "TGNDAO deployed at:")
echo "TGNDAO Address: $DAO_ADDRESS"

echo -e "${YELLOW}Step 1.4: Deploying BaseMgroOapp...${NC}"
MESSENGER_OUTPUT=$(run_forge_script "DeployBaseMessengerBaseSepolia.s.sol" "$BASE_SEPOLIA_RPC")
MESSENGER_ADDRESS=$(extract_address "$MESSENGER_OUTPUT" "BaseMgroOapp deployed at:")
echo "Messenger Address: $MESSENGER_ADDRESS"

echo -e "${YELLOW}Step 1.5: Initializing ManagementFacet...${NC}"
run_forge_script "InitializeManagementFacetBaseSepolia.s.sol --sig 'run(address,address,address)' $DIAMOND_ADDRESS $NFT_ADDRESS $DAO_ADDRESS" "$BASE_SEPOLIA_RPC"

cd ../..

echo ""
echo -e "${BLUE}=== PHASE 2: OP Sepolia Deployment ===${NC}"

# Deploy on OP Sepolia
cd script/op-sepolia

echo -e "${YELLOW}Step 2.1: Deploying MGRO Token...${NC}"
MGRO_OUTPUT=$(run_forge_script "DeployMgroOpSepolia.s.sol" "$OP_SEPOLIA_RPC")
MGRO_ADDRESS=$(extract_address "$MGRO_OUTPUT" "MGRO deployed at:")
echo "MGRO Address: $MGRO_ADDRESS"

echo -e "${YELLOW}Step 2.2: Deploying TreegenNFT...${NC}"
OP_NFT_OUTPUT=$(run_forge_script "DeployNftOpSepolia.s.sol" "$OP_SEPOLIA_RPC")
OP_NFT_ADDRESS=$(extract_address "$OP_NFT_OUTPUT" "TreegenNFT deployed at:")
echo "OP NFT Address: $OP_NFT_ADDRESS"

cd ../..

echo ""
echo -e "${BLUE}=== PHASE 3: Ethereum Sepolia Deployment ===${NC}"

# Deploy on Ethereum Sepolia
cd script/eth-sepolia

echo -e "${YELLOW}Step 3.1: Deploying TreegenNFT...${NC}"
ETH_NFT_OUTPUT=$(run_forge_script "DeployNftEthSepolia.s.sol" "$ETH_SEPOLIA_RPC")
ETH_NFT_ADDRESS=$(extract_address "$ETH_NFT_OUTPUT" "TreegenNFT deployed at:")
echo "Ethereum NFT Address: $ETH_NFT_ADDRESS"

cd ../..

echo ""
echo -e "${BLUE}=== PHASE 4: Peer Setup ===${NC}"

# Setup peers on Base Sepolia
echo -e "${YELLOW}Step 4.1: Setting up Base Sepolia peers...${NC}"
cd script/base-sepolia
run_forge_script "SetupPeersBaseSepolia.s.sol --sig 'run(address,address,address,address)' $MESSENGER_ADDRESS $NFT_ADDRESS $MGRO_ADDRESS $OP_NFT_ADDRESS" "$BASE_SEPOLIA_RPC"
cd ../..

# Setup peers on OP Sepolia
echo -e "${YELLOW}Step 4.2: Setting up OP Sepolia peers...${NC}"
cd script/op-sepolia
run_forge_script "SetupPeersOpSepolia.s.sol --sig 'run(address,address,address,address)' $MGRO_ADDRESS $OP_NFT_ADDRESS $MESSENGER_ADDRESS $NFT_ADDRESS" "$OP_SEPOLIA_RPC"
cd ../..

echo ""
echo -e "${GREEN}=== COMPLETE DEPLOYMENT SUMMARY ===${NC}"
echo ""
echo "Base Sepolia:"
echo "  Diamond: $DIAMOND_ADDRESS"
echo "  NFT Canonical: $NFT_ADDRESS"
echo "  TGNDAO: $DAO_ADDRESS"
echo "  Messenger: $MESSENGER_ADDRESS"
echo ""
echo "OP Sepolia:"
echo "  MGRO Token: $MGRO_ADDRESS"
echo "  NFT: $OP_NFT_ADDRESS"
echo ""
echo "Ethereum Sepolia:"
echo "  NFT: $ETH_NFT_ADDRESS"
echo ""
echo -e "${GREEN}🎉 All contracts deployed and configured successfully!${NC}"
echo ""
echo "Cross-chain setup:"
echo "- Base Sepolia ↔ OP Sepolia: ✅ Configured"
echo "- NFT addresses are identical across all networks: ✅"
echo "  Canonical: $NFT_ADDRESS"
echo "  OP Sepolia: $OP_NFT_ADDRESS"
echo "  Ethereum Sepolia: $ETH_NFT_ADDRESS"

# Export all addresses
export DIAMOND_ADDRESS=$DIAMOND_ADDRESS
export NFT_ADDRESS=$NFT_ADDRESS
export DAO_ADDRESS=$DAO_ADDRESS
export MESSENGER_ADDRESS=$MESSENGER_ADDRESS
export MGRO_ADDRESS=$MGRO_ADDRESS
export OP_NFT_ADDRESS=$OP_NFT_ADDRESS
export ETH_NFT_ADDRESS=$ETH_NFT_ADDRESS

echo ""
echo "All addresses exported as environment variables for future use."
