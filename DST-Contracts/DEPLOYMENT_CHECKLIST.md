### Contract Setup and Operations Checklist

## Prerequisites
- **Foundry/Node**: Install Foundry (forge/cast) and Node.js
- **.env**: set `RPC_API_KEY` and keep your `TESTNET_PRIVATE_KEY` available to export inline when running scripts
- **RPCs**: `foundry.toml` already configured to use `RPC_API_KEY` for `base_sepolia`, `optimism_sepolia`, `base`, `celo`
- **Deps**:
  - `git submodule update --init --recursive`
  - `forge build -vvvv`

## Testnet rollout (recommended)
- **Deploy MGRO (OP Sepolia)**:
```bash
RPC_API_KEY=... TESTNET_PRIVATE_KEY=0x... ./scripts/deploy_mgro_celo.sh sepolia
# Note: Extract MGRO address from console output of deploy_mgro_celo.sh
```
- **Deploy Diamond stack (Base Sepolia)**:
```bash
RPC_API_KEY=... TESTNET_PRIVATE_KEY=0x... MGRO_ADDRESS=$MGRO_ADDRESS ./scripts/deploy_base.sh sepolia
```
- Outputs: Check console output for deployed addresses

## Mainnet rollout (plan)
- **Deploy MGRO (Celo mainnet)**:
```bash
RPC_API_KEY=... TESTNET_PRIVATE_KEY=0x... ./scripts/deploy_mgro_celo.sh mainnet
```
- **Deploy Diamond stack (Base mainnet)**:
```bash
# Note: Extract MGRO address from console output of deploy_mgro_celo.sh
RPC_API_KEY=... TESTNET_PRIVATE_KEY=0x... MGRO_ADDRESS=$MGRO_ADDRESS ./scripts/deploy_base.sh mainnet
```

## Messenger/Bridge setup (Base)
- If not auto-set during FullSetup, deploy and wire the messenger:
```bash
# Deploy messenger (Base)
RPC_API_KEY=... TESTNET_PRIVATE_KEY=0x... \
# Note: Extract Diamond address from console output of deploy_base.sh
forge script script/DeployMessenger.s.sol:DeployMessenger \
  --rpc-url base_sepolia --broadcast --verify -vvvv
```
- Management facet xchain configuration (done by FullSetup if envs provided):
  - **Messenger**: `xchainSetMessenger(<messenger>)`
  - **DstEid**: `xchainSetDstEid(<partner_eid>)` (Base Sepolia → 40232, Base mainnet → 30125)
  - **Options**: `xchainSetOptions(<bytes>)` (gas limit and options)

## Administration (post-deploy)
- **DAO-controlled** (set during `initialize`):
  - `setFeeCollector(address)`
  - `setPurchaseToken(address,uint256 price)`
- **Owner-controlled**:
  - `setVerificationContract(address)`
  - `setMgroToken(address)` - **Set MGRO token when available**
  - `addBaseURI(string)` up to 3 entries
  - `mintNFT(address)` (admin mint)
- **End-user flow** (optional):
  - Ensure `feeCollector` set, `buyToken` set to MGRO, and `nftPrice` > 0
  - User approves diamond for `nftPrice` and calls `mintNFTasUser()`

## Adding MGRO Token Later
If MGRO token is not available during initial deployment:
- [ ] Deploy MGRO on the target chain (OP Sepolia/Celo) using `./scripts/deploy_mgro_celo.sh`
- [ ] Set the MGRO token on the Diamond using:
  ```bash
  cast call <DIAMOND_ADDRESS> "setMgroToken(address)" <MGRO_ADDRESS> --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
  ```
- [ ] Update purchase token configuration:
  ```bash
  cast call <DIAMOND_ADDRESS> "setPurchaseToken(address,uint256)" <MGRO_ADDRESS> <PRICE> --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
  ```

## Upgrades (Diamond / EIP-2535)
- Build new facet(s) and deploy with `--verify`
- Prepare diamond cut (Add/Replace/Remove selectors)
- Execute `diamondCut(cuts, init, calldata)` from owner
- Use an `init` initializer for storage migrations when needed
- Validate:
  - Loupe facet shows expected facets
  - DAO/owner permissions enforced
  - Critical flows green on fork/testnet

## Future: MGRO on Base
- Deploy MGRO on Base when desired (testnet or mainnet) using `script/deployMgroCelo.s.sol`
- Configure OFT peers and endpoints per LayerZero/OFT requirements
- Update management chain config:
  - `xchainSetDstEid(newPartnerEid)`
  - `xchainSetMessenger(newMessenger)` (if changed)
  - `xchainSetOptions(...)`
- If MGRO and Diamond are on the same chain, set `buyToken` to local MGRO and consider reducing cross-chain dependencies

## Troubleshooting
- Env present for each run: `RPC_API_KEY`, `TESTNET_PRIVATE_KEY`, and any overrides (`MGRO_ADDRESS`, `DAO_ADDRESS`, `FEE_COLLECTOR`, `PURCHASE_PRICE`, `MESSENGER_ADDRESS`, `DST_EID`)
- If verification fails, re-run with `-vvvv` and confirm solc version and import paths match `foundry.toml`
- Cross-chain send reverts: ensure messenger and dstEid set; include sufficient native fee

## Handy commands
```bash
forge build -vvvv
forge test -vvvv
```

Notes: Primary scripts are `script/FullSetup.s.sol`, `script/deployMgroCelo.s.sol`, `script/DeployMessenger.s.sol`, plus bash helpers in `scripts/`.


