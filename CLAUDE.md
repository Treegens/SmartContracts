# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
yarn compile                 # compile contracts (hardhat compile)
yarn test                    # run full test suite (REPORT_GAS=true hardhat test --network hardhat)
npx hardhat test test/unit/MangroveTreeNFT.test.ts   # run a single test file
npx hardhat test test/unit/MangroveTreeNFT.test.ts --grep "mint"   # run matching tests only
yarn lint                    # eslint over ts files
yarn check-types             # tsc --noEmit --incremental
yarn format                  # prettier --write over ts and sol files
yarn clean                   # hardhat clean (clears artifacts/cache/typechain-types)
yarn deploy                  # ts-node scripts/runHardhatDeployWithPK.ts (deploys via hardhat-deploy)
yarn flatten                 # hardhat flatten
yarn hardhat-verify           # verify on etherscan
yarn chain                   # local hardhat node (no auto-deploy)
yarn fork                    # local hardhat node forking mainnet (MAINNET_FORKING_ENABLED=true)
```

There is no README; this file and `.env.example` are the primary onboarding docs.

## Architecture

This is a Hardhat + `hardhat-deploy` project (TypeScript, ethers v6, TypeChain). Solidity version is pinned to `0.8.28` with the optimizer and `viaIR` enabled (see `hardhat.config.ts`).

### Contract / interface pairing convention

Every concrete contract in `contracts/` has a matching interface in `contracts/interfaces/` (`I<Name>.sol`), and the contract inherits from its interface (e.g. `contract MGRO is ERC20Capped, ..., IMGRO`). The interface is the source of truth for external function signatures, custom errors that callers should know about, events, and NatSpec docs; the contract implementation uses `/// @inheritdoc IXxx` on overridden functions rather than repeating NatSpec. **When adding a new concrete contract, add its interface first (or alongside it)** — this repo treats a contract without a matching interface as incomplete.

### Contract map

- `MGRO.sol` / `IMGRO.sol` — ERC20 reward token: capped at 1B (`ERC20Capped`), burnable, EIP-2612 permit, role-gated mint (`MINTER_ROLE`), permissionless self-burn.
- `TGNVault.sol` / `ITGNVault.sol` — staking vault for the TGN token with role-gated slashing (`SLASHER_ROLE`) to a configurable treasury.
- `BaseTreePlantingNFT.sol` — abstract ERC-721 (`ERC721URIStorage` + `AccessControl`) implementing `ITreePlantingNFT`. Holds all shared minting/storage/view logic for verified tree-planting submissions: role-gated mint (`MINTER_ROLE`), on-chain `PlantingRecord` (GCS storage keys, tree type, lat/lng, tree count, verification timestamp) keyed by `tokenId`, and submission-id → token-id dedup tracking to prevent double-minting the same verified submission.
- `MangroveTreeNFT.sol` / `NonMangroveTreeNFT.sol` — thin concrete contracts that just fix `name`/`symbol` and inherit everything from `BaseTreePlantingNFT`. There is a **single shared interface** `ITreePlantingNFT.sol` for both (and for the base contract) — do not create per-subclass interfaces; new tree-category NFTs should follow the same "extend `BaseTreePlantingNFT`, no new interface" pattern unless behavior actually diverges.
- Video assets referenced by `PlantingRecord` live in Google Cloud Storage; only storage keys are stored on-chain. `tokenURI` points to an off-chain HTTPS metadata JSON containing the full public video URLs.

### Deploy scripts (`deploy/`)

`hardhat-deploy` numbered scripts, each with a `tags` export used to select what to deploy. Deployed addresses/ABIs land in `deployments/<network>/`. Convention per script:
- Read config from env vars via `deploy/env.ts` helpers (`envOrDefault`, `envIntOrDefault`), defaulting to the deployer account/sensible values when unset — see `.env.example` for the documented vars per contract's constructor args.
- After deploying an access-controlled contract, optionally grant an operational role (e.g. `MINTER_ROLE`, `SLASHER_ROLE`) to an address from an env var if that role isn't already held — deploys stay idempotent/re-runnable.
- The `deploy` hardhat task is extended in `hardhat.config.ts` to run `scripts/generateTsAbis.ts` after deploying, which regenerates TypeScript ABI exports.

### Tests (`test/unit/`)

Mocha/Chai via `@nomicfoundation/hardhat-chai-matchers`, one file per contract, using TypeChain types imported from `../../typechain-types`. Standard structure: deploy fresh contract in `beforeEach`, grant any operational roles needed, then group assertions in nested `describe` blocks (`Deployment`, `mint`, etc.). Use `ethers.id('ROLE_NAME')` to compute role hashes and `ethers.ZeroHash` for `DEFAULT_ADMIN_ROLE`.

### Custom errors

Contracts use custom errors namespaced by contract name (e.g. `BaseTreePlantingNFT__ZeroAddress`, `MGRO__InvalidInput`, `TGNVault__InvalidInput`) rather than require strings. Follow this `<ContractName>__<Reason>` naming when adding new errors.
