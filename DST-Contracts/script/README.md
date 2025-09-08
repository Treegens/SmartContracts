# Deployment Scripts

This directory contains organized deployment scripts for different networks.

## Directory Structure

```
script/
├── base-sepolia/           # Base Sepolia testnet scripts
│   ├── DeployDiamondBaseSepolia.s.sol
│   ├── DeployNftCanonicalBaseSepolia.s.sol
│   ├── DeployTGNDAOBaseSepolia.s.sol
│   ├── DeployBaseMessengerBaseSepolia.s.sol
│   ├── InitializeManagementFacetBaseSepolia.s.sol
│   ├── SetupPeersBaseSepolia.s.sol
│   └── deploy_base_sepolia.sh
├── op-sepolia/            # OP Sepolia testnet scripts
│   ├── DeployMgroOpSepolia.s.sol
│   ├── DeployNftOpSepolia.s.sol
│   ├── SetupPeersOpSepolia.s.sol
│   ├── deployCeloOapp.s.sol
│   └── deploy_op_sepolia.sh
├── eth-sepolia/           # Ethereum Sepolia testnet scripts
│   ├── DeployNftEthSepolia.s.sol
│   └── deploy_eth_sepolia.sh
├── full_deployment.sh     # Complete multi-network deployment
└── ChainConfig.s.sol      # Chain configuration library
```

## Network Deployments

### Base Sepolia (Chain ID: 84532)
Deploys the Diamond management contracts, canonical NFT, and initializes everything.

**Contracts:**
- Diamond (with all facets)
- TreegenNFT Canonical (CREATE3)
- TGNDAO
- BaseMgroOapp (Messenger)
- ManagementFacet initialization with USDC

**Usage:**
```bash
cd script/base-sepolia
./deploy_base_sepolia.sh                    # Interactive mode
./deploy_base_sepolia.sh --dry-run         # Simulation only
./deploy_base_sepolia.sh --auto-confirm    # Auto-confirm broadcast
```

### OP Sepolia (Chain ID: 11155420)
Deploys MGRO token and NFT with same address as canonical.

**Contracts:**
- MGRO Token (CREATE3)
- TreegenNFT (same address as canonical)
- CeloMgroOapp (optional)

**Usage:**
```bash
cd script/op-sepolia
./deploy_op_sepolia.sh                    # Interactive mode
./deploy_op_sepolia.sh --dry-run         # Simulation only
./deploy_op_sepolia.sh --auto-confirm    # Auto-confirm broadcast
```

### Ethereum Sepolia (Chain ID: 11155111)
Deploys TreegenNFT with same address as canonical.

**Contracts:**
- TreegenNFT (same address as canonical on Base Sepolia)

**Usage:**
```bash
cd script/eth-sepolia
./deploy_eth_sepolia.sh                    # Interactive mode
./deploy_eth_sepolia.sh --dry-run         # Simulation only
./deploy_eth_sepolia.sh --auto-confirm    # Auto-confirm broadcast
```

### Complete Multi-Network Deployment
Deploys all contracts across all networks with proper initialization and peer setup.

**Features:**
- Automated deployment across all networks
- ManagementFacet initialization with correct parameters
- Peer setup and enforced options configuration
- Gas limit configuration (BaseMgroOapp: 30000, CeloMgroOapp: 150000, OFT/ONFT: 200000)
- Simulation and broadcast modes with confirmation

**Usage:**
```bash
./script/full_deployment.sh                    # Interactive mode
./script/full_deployment.sh --dry-run         # Simulation only
./script/full_deployment.sh --auto-confirm    # Auto-confirm broadcast
```

## Environment Variables

Set the following environment variables before running scripts:

```bash
export PRIVATE_KEY="your_private_key"
export BASESCAN_API_KEY="your_basescan_api_key"
export OPTIMISTIC_ETHERSCAN_API_KEY="your_optimism_etherscan_api_key"
export ETHERSCAN_API_KEY="your_etherscan_api_key"
```


## Features

- **CREATE3 Deployment**: Deterministic addresses using Solady CREATE3
- **Automatic Verification**: Scripts include Etherscan verification
- **Error Handling**: Bash scripts with proper error checking
- **Address Export**: Deployed addresses are exported for reuse
- **Cross-chain Setup**: Automatic peer configuration with enforced options
- **Gas Limit Configuration**: Pre-configured gas limits for different contract types
- **Simulation & Broadcast Modes**: Choose between dry-run simulation or actual deployment
- **Interactive Confirmation**: Manual confirmation before broadcasting transactions

## Contract Addresses

After deployment, addresses are exported as environment variables:

**Base Sepolia:**
- `DIAMOND_ADDRESS`
- `NFT_ADDRESS`
- `DAO_ADDRESS`
- `MESSENGER_ADDRESS`

**OP Sepolia:**
- `MGRO_ADDRESS`
- `OP_NFT_ADDRESS` (same as Base Sepolia NFT)

**Ethereum Sepolia:**
- `ETH_NFT_ADDRESS` (same as Base Sepolia NFT)

## Configuration Details

### USDC Addresses (Testnets)
- **Base Sepolia**: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **OP Sepolia**: `0x5dEaC602762362FE5f135Fa5904351916CA540D95`
- **Ethereum Sepolia**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`

### Gas Limits for Enforced Options
- **BaseMgroOapp**: 30000 gas limit
- **CeloMgroOapp**: 150000 gas limit
- **OFT (MGRO)**: 200000 gas limit
- **ONFT (TreegenNFT)**: 200000 gas limit

### ManagementFacet Initialization Parameters
- `_minter`: TreegenNFT_Canonical address
- `_token`: `address(0)` (MGRO to be set later)
- `_dao`: TGNDAO address
- `_buyToken`: USDC address for the respective network
