#!/bin/bash

# Ethereum Sepolia Deployment Script
# This script deploys TreegenNFT contract on Ethereum Sepolia
#
# Usage:
#   ./deploy_eth_sepolia.sh [--dry-run] [--auto-confirm]
#
# Options:
#   --dry-run      : Run simulation only, do not broadcast
#   --auto-confirm : Automatically confirm broadcast after successful simulation

set -e

source .env

# Parse command line arguments
DRY_RUN=false
AUTO_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --auto-confirm)
            AUTO_CONFIRM=true
            shift
            ;;
        *)
            # If it's not a flag, treat it as PRIVATE_KEY
            if [[ -z "$PRIVATE_KEY" ]]; then
                PRIVATE_KEY="$1"
            fi
            shift
            ;;
    esac
done

echo "=== Ethereum Sepolia Deployment Script ==="
echo "Starting deployment on Ethereum Sepolia..."

# Configuration
export PRIVATE_KEY=${PRIVATE_KEY:-$1}
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

echo "Using RPC: $ETH_SEPOLIA_RPC"
echo "Mode: $(if $DRY_RUN; then echo 'DRY RUN (Simulation Only)'; else echo 'BROADCAST'; fi)"

# Function to run forge script
run_forge_script() {
    local script_name=$1
    local script_path="script/eth-sepolia/$script_name.s.sol"

    echo -e "${YELLOW}Running $script_name...${NC}"

    if $DRY_RUN; then
        echo -e "${BLUE}Running simulation for $script_name...${NC}"
        if forge script $script_path \
            --rpc-url $ETH_SEPOLIA_RPC \
            --private-key $PRIVATE_KEY \
            -vvvv; then
            echo -e "${GREEN}✓ $script_name simulation successful${NC}"
            return 0
        else
            echo -e "${RED}✗ $script_name simulation failed${NC}"
            return 1
        fi
    else
        if $AUTO_CONFIRM; then
            echo -e "${YELLOW}Auto-confirming broadcast for $script_name...${NC}"
            broadcast=true
        else
            echo -e "${YELLOW}Simulation successful. Broadcast transaction? (y/N)${NC}"
            read -r -n 1 response
            echo
            if [[ "$response" =~ ^[Yy]$ ]]; then
                broadcast=true
            else
                echo -e "${YELLOW}Broadcast cancelled${NC}"
                return 0
            fi
        fi

        if $broadcast; then
            if forge script $script_path \
                --rpc-url $ETH_SEPOLIA_RPC \
                --private-key $PRIVATE_KEY \
                --broadcast \
                --verify \
                --etherscan-api-key $ETHERSCAN_API_KEY \
                -vvvv; then
                echo -e "${GREEN}✓ $script_name broadcast successful${NC}"
                return 0
            else
                echo -e "${RED}✗ $script_name broadcast failed${NC}"
                return 1
            fi
        fi
    fi
}

# Step 1: Deploy TreegenNFT (same address as canonical)
echo -e "${YELLOW}Step 1: Deploying TreegenNFT...${NC}"
NFT_ADDRESS=$(run_forge_script "DeployNftEthSepolia" | grep "TreegenNFT deployed at:" | awk '{print $4}')
echo "NFT Address: $NFT_ADDRESS"

# Summary
echo ""
echo "=== Ethereum Sepolia Deployment Summary ==="
echo "NFT Address: $NFT_ADDRESS"
echo ""
echo -e "${GREEN}All Ethereum Sepolia contracts deployed successfully!${NC}"

# Export addresses for next steps
export NFT_ADDRESS

echo ""
echo "Addresses exported as environment variables:"
echo "NFT_ADDRESS=$NFT_ADDRESS"
