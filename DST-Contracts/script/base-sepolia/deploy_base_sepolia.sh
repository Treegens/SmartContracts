#!/bin/bash

# Base Sepolia Deployment Script
# This script deploys all contracts needed on Base Sepolia
#
# Usage:
#   ./deploy_base_sepolia.sh [--dry-run] [--auto-confirm]
#
# Options:
#   --dry-run      : Run simulation only, do not broadcast
#   --auto-confirm : Automatically confirm broadcast after successful simulation

set -e

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

echo "=== Base Sepolia Deployment Script ==="
echo "Starting deployment on Base Sepolia..."

# Configuration
export PRIVATE_KEY=${PRIVATE_KEY:-$1}
export BASE_SEPOLIA_RPC="https://sepolia.base.org"

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

echo "Using RPC: $BASE_SEPOLIA_RPC"
echo "Mode: $(if $DRY_RUN; then echo 'DRY RUN (Simulation Only)'; else echo 'BROADCAST'; fi)"

# Function to run forge script
run_forge_script() {
    local script_name=$1
    local script_path="script/base-sepolia/$script_name.s.sol"
    local extra_args="${2:-}"

    echo -e "${YELLOW}Running $script_name...${NC}"

    if $DRY_RUN; then
        echo -e "${BLUE}Running simulation for $script_name...${NC}"
        if forge script $script_path \
            --rpc-url $BASE_SEPOLIA_RPC \
            --private-key $PRIVATE_KEY \
            $extra_args \
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
                --rpc-url $BASE_SEPOLIA_RPC \
                --private-key $PRIVATE_KEY \
                --broadcast \
                --verify \
                --etherscan-api-key $BASESCAN_API_KEY \
                $extra_args \
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

# Step 1: Deploy Diamond
echo -e "${YELLOW}Step 1: Deploying Diamond...${NC}"
DIAMOND_ADDRESS=$(run_forge_script "DeployDiamondBaseSepolia" | grep "Diamond deployed at:" | awk '{print $4}')
echo "Diamond Address: $DIAMOND_ADDRESS"

# Step 2: Deploy TreegenNFT Canonical
echo -e "${YELLOW}Step 2: Deploying TreegenNFT Canonical...${NC}"
NFT_ADDRESS=$(run_forge_script "DeployNftCanonicalBaseSepolia" | grep "TreegenNFT deployed at:" | awk '{print $4}')
echo "NFT Canonical Address: $NFT_ADDRESS"

# # Step 3: Deploy TGNDAO
# echo -e "${YELLOW}Step 3: Deploying TGNDAO...${NC}"
# DAO_ADDRESS=$(run_forge_script "DeployTGNDAOBaseSepolia" | grep "TGNDAO deployed at:" | awk '{print $4}')
# echo "TGNDAO Address: $DAO_ADDRESS"

# Step 4: Deploy BaseMgroOapp (Messenger)
echo -e "${YELLOW}Step 4: Deploying BaseMgroOapp...${NC}"
export DIAMOND_ADDRESS=$DIAMOND_ADDRESS
MESSENGER_OUTPUT=$(run_forge_script "DeployBaseMessengerBaseSepolia" "--sig run(address) $DIAMOND_ADDRESS")
MESSENGER_ADDRESS=$(echo "$MESSENGER_OUTPUT" | grep -oP 'BaseMgroOapp deployed at: \K0x[a-fA-F0-9]{40}' || echo "")
if [ -z "$MESSENGER_ADDRESS" ]; then
    echo -e "${RED}✗ Failed to extract messenger address${NC}"
    exit 1
fi
echo "Messenger Address: $MESSENGER_ADDRESS"

# Step 5: Initialize ManagementFacet
echo -e "${YELLOW}Step 5: Initializing ManagementFacet...${NC}"
if ! run_forge_script "InitializeManagementFacetBaseSepolia" "--sig run(address,address,address) $DIAMOND_ADDRESS $NFT_ADDRESS 0x11d12b5F7d973B5E38A592C17971bE2Cac5971B7"; then
    echo -e "${RED}✗ ManagementFacet initialization failed${NC}"
    exit 1
fi

# Note: Peer setup will be done after OP Sepolia deployment is complete
# This requires the OP Sepolia contract addresses

# Summary
echo ""
echo "=== Base Sepolia Deployment Summary ==="
echo "Diamond Address: $DIAMOND_ADDRESS"
echo "NFT Canonical Address: $NFT_ADDRESS"
# echo "TGNDAO Address: $DAO_ADDRESS"
echo "Messenger Address: $MESSENGER_ADDRESS"
echo ""
echo -e "${GREEN}All Base Sepolia contracts deployed and initialized successfully!${NC}"
echo -e "${YELLOW}Note: Run peer setup after OP Sepolia deployment${NC}"

# Export addresses for next steps
export DIAMOND_ADDRESS
export NFT_ADDRESS
export DAO_ADDRESS
export MESSENGER_ADDRESS

echo ""
echo "Addresses exported as environment variables:"
echo "DIAMOND_ADDRESS=$DIAMOND_ADDRESS"
echo "NFT_ADDRESS=$NFT_ADDRESS"
echo "DAO_ADDRESS=$DAO_ADDRESS"
echo "MESSENGER_ADDRESS=$MESSENGER_ADDRESS"
