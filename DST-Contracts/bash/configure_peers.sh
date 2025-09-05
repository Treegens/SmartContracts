#!/bin/bash

# Configure ONFT Peer Relationships
# Usage: ./configure_peers.sh <local_contract> <remote_chain> <remote_contract>
# Example: ./configure_peers.sh 0x1234... sepolia 0x5678...

set -e

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    echo "Usage: $0 <local_contract> <remote_chain> <remote_contract>"
    echo "Example: $0 0x1234567890123456789012345678901234567890 sepolia 0x5678901234567890123456789012345678901234"
    exit 1
fi

LOCAL_CONTRACT=$1
REMOTE_CHAIN=$2
REMOTE_CONTRACT=$3

# Set environment variables
export LOCAL_CONTRACT=$LOCAL_CONTRACT
export REMOTE_CHAIN=$REMOTE_CHAIN
export REMOTE_CONTRACT=$REMOTE_CONTRACT

echo "Configuring peer relationship..."
echo "Local Contract: $LOCAL_CONTRACT"
echo "Remote Chain: $REMOTE_CHAIN"
echo "Remote Contract: $REMOTE_CONTRACT"

# Configure the peer relationship
forge script script/onft/ConfigureONFTPeers.s.sol:ConfigureONFTPeers \
    --rpc-url $REMOTE_CHAIN \
    --broadcast

echo "Peer relationship configured successfully!"
echo "Local contract can now send messages to remote contract on $REMOTE_CHAIN"
