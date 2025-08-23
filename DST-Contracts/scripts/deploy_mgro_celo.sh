#!/usr/bin/env bash
set -euo pipefail

# Usage: RPC_API_KEY=... TESTNET_PRIVATE_KEY=0x... ./scripts/deploy_mgro_celo.sh [sepolia|mainnet]

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

RPC_ALIAS="op_sepolia"
CHAIN_NAME="op-sepolia"
if [[ "$NET" == "mainnet" ]]; then
  RPC_ALIAS="celo"
  CHAIN_NAME="celo-mainnet"
fi

export RPC_API_KEY

echo "[deploy_mgro] Deploying MGRO on $CHAIN_NAME"
echo "[deploy_mgro] Using RPC alias: $RPC_ALIAS"
if [[ -n "${MGRO_DELEGATE:-}" ]]; then echo "[deploy_mgro] MGRO_DELEGATE=$MGRO_DELEGATE"; fi

# Run the DeployMgroCelo script directly
forge script script/DeployMgroCelo.s.sol \
  --rpc-url "$RPC_ALIAS" \
  --private-key "$TESTNET_PRIVATE_KEY" \
  --broadcast --verify -vvvv

echo "[deploy_mgro] MGRO deployment completed on $CHAIN_NAME"
echo "[deploy_mgro] Check the console output above for deployed addresses"


