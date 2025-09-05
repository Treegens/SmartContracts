#!/usr/bin/env bash
set -euo pipefail

# Usage: RPC_API_KEY=... TESTNET_PRIVATE_KEY=0x... ./scripts/deploy_base.sh [sepolia|mainnet]

source .env

NET=${1:-sepolia}

if [[ -z "${RPC_API_KEY:-}" ]]; then
  echo "RPC_API_KEY is required" >&2
  exit 1
fi
if [[ -z "${TESTNET_PRIVATE_KEY:-}" ]]; then
  echo "TESTNET_PRIVATE_KEY is required" >&2
  exit 1
fi

RPC_ALIAS="base_sepolia"
CHAIN_NAME="base-sepolia"
if [[ "$NET" == "mainnet" ]]; then
  RPC_ALIAS="base"
  CHAIN_NAME="base-mainnet"
fi

export RPC_API_KEY

echo "[deploy_base] Deploying Diamond stack on $CHAIN_NAME"
echo "[deploy_base] Using RPC alias: $RPC_ALIAS"
if [[ -n "${DAO_ADDRESS:-}" ]]; then echo "[deploy_base] DAO_ADDRESS=$DAO_ADDRESS"; fi
if [[ -n "${FEE_COLLECTOR:-}" ]]; then echo "[deploy_base] FEE_COLLECTOR=$FEE_COLLECTOR"; fi
if [[ -n "${PURCHASE_PRICE:-}" ]]; then echo "[deploy_base] PURCHASE_PRICE=$PURCHASE_PRICE"; fi
if [[ -n "${MESSENGER_ADDRESS:-}" ]]; then echo "[deploy_base] MESSENGER_ADDRESS=$MESSENGER_ADDRESS"; fi

# Expect MGRO already deployed on partner chain; pass MGRO_ADDRESS if you want to reuse
if [[ -n "${MGRO_ADDRESS:-}" ]]; then
  echo "[deploy_base] Using MGRO_ADDRESS=$MGRO_ADDRESS"
fi

# Optionally deploy messenger if MANAGEMENT_ADDRESS provided and no MESSENGER_ADDRESS
if [[ -n "${MANAGEMENT_ADDRESS:-}" && -z "${MESSENGER_ADDRESS:-}" ]]; then
  echo "[deploy_base] Deploying BaseMgroOapp for management=$MANAGEMENT_ADDRESS"
  forge script script/DeployMessenger.s.sol:DeployMessenger \
    --rpc-url "$RPC_ALIAS" \
    --private-key "$TESTNET_PRIVATE_KEY" \
    --broadcast --verify -vvvv
fi

# Run the FullSetup script directly
forge script script/FullSetup.s.sol:FullSetup \
  --rpc-url "$RPC_ALIAS" \
  --private-key "$TESTNET_PRIVATE_KEY" \
  --broadcast --verify -vvvv

echo "[deploy_base] FullSetup deployment completed on $CHAIN_NAME"
echo "[deploy_base] Check the console output above for deployed addresses"

