# ONFT Deployment Checklist

Use this checklist to ensure a complete and secure ONFT deployment.

## Pre-Deployment

- [ ] Set up environment variables in `.env` file
- [ ] Verify private key has sufficient funds on target networks
- [ ] Test contracts locally with `forge test`
- [ ] Review security parameters and DVN configurations
- [ ] Plan deployment order (source chain first for adapters)

## Deployment Phase

### 1. Deploy Contracts

#### For New NFT Collections (ONFT721)
- [ ] Deploy to Chain A: `./bash/deploy_onft.sh <network> <name> <symbol>`
- [ ] Deploy to Chain B: `./bash/deploy_onft.sh <network> <name> <symbol>`
- [ ] Deploy to Chain C: `./bash/deploy_onft.sh <network> <name> <symbol>`
- [ ] Record all contract addresses

#### For Existing NFT Collections (ONFT721Adapter)
- [ ] Deploy adapter to source chain: `./bash/deploy_onft_adapter.sh <network> <token_address>`
- [ ] Deploy ONFT721 to destination chains: `./bash/deploy_onft.sh <network> <name> <symbol>`
- [ ] Record all contract addresses

### 2. Configure Peer Relationships

- [ ] Configure Chain A → Chain B: `./bash/configure_peers.sh <chain_a_contract> <chain_b> <chain_b_contract>`
- [ ] Configure Chain B → Chain A: `./bash/configure_peers.sh <chain_b_contract> <chain_a> <chain_a_contract>`
- [ ] Configure Chain A → Chain C: `./bash/configure_peers.sh <chain_a_contract> <chain_c> <chain_c_contract>`
- [ ] Configure Chain C → Chain A: `./bash/configure_peers.sh <chain_c_contract> <chain_a> <chain_a_contract>`
- [ ] Configure Chain B → Chain C: `./bash/configure_peers.sh <chain_b_contract> <chain_c> <chain_c_contract>`
- [ ] Configure Chain C → Chain B: `./bash/configure_peers.sh <chain_c_contract> <chain_b> <chain_b_contract>`
 
### 3. Configure Security Parameters

- [ ] Set DVN configurations for each chain pair
- [ ] Configure message execution options
- [ ] Set appropriate gas limits
- [ ] Review and test security settings

### 4. Initial Testing

- [ ] Mint test NFTs on source chain
- [ ] Send test NFT cross-chain
- [ ] Verify NFT received on destination chain
- [ ] Test reverse transfer (back to source chain)
- [ ] Verify total supply consistency

## Post-Deployment

### 5. Verification

- [ ] Verify all contracts on block explorers
- [ ] Test all cross-chain pathways
- [ ] Verify peer configurations: `cast call <contract> "peers(uint32)" <eid>`
- [ ] Check enforced options: `cast call <contract> "enforcedOptions(uint32,uint16)" <eid> <msgType>`

### 6. Documentation

- [ ] Document all contract addresses
- [ ] Record deployment parameters
- [ ] Create user guides
- [ ] Document any custom configurations

### 7. Security Review

- [ ] Review all peer relationships
- [ ] Verify DVN configurations
- [ ] Check gas limits are appropriate
- [ ] Ensure proper access controls
- [ ] Test emergency recovery procedures

## Production Readiness

- [ ] All tests passing
- [ ] Security audit completed (if required)
- [ ] Monitoring and alerting set up
- [ ] Backup and recovery procedures documented
- [ ] Team trained on operations
- [ ] Incident response plan ready

## Emergency Procedures

- [ ] Document emergency recovery steps
- [ ] Test emergency functions (if applicable)
- [ ] Prepare communication plan for incidents
- [ ] Set up monitoring for failed transactions

## Maintenance

- [ ] Schedule regular security reviews
- [ ] Monitor cross-chain transaction success rates
- [ ] Update configurations as needed
- [ ] Keep dependencies updated
- [ ] Monitor LayerZero protocol updates

---

## Quick Commands Reference

```bash
# Deploy ONFT721
./bash/deploy_onft.sh sepolia "MyONFT" "MONFT"

# Deploy ONFT721Adapter
./bash/deploy_onft_adapter.sh sepolia 0x1234...

# Configure peers
./bash/configure_peers.sh 0x1234... sepolia 0x5678...

# Mint NFT
./bash/mint_onft.sh 0x1234... 0x5678... 1

# Send cross-chain
./bash/send_onft.sh 0x1234... sepolia 0x5678... 1
```

## Network Endpoint IDs

- Sepolia: 40161
- Base Sepolia: 40245
- Optimism Sepolia: 40232
- Arbitrum Sepolia: 40231
- Polygon Amoy: 40267
- Avalanche Fuji: 40106
- BSC Testnet: 40102

## LayerZero Endpoints

- Mainnet: 0x1a44076050125825900e736c501f859c50fE728c
- Testnet: 0x6EDCE65403992e310A62460808c4b910D972f10f
