# Diamond Standard Implementation of the Management Smart Contract

## Management Contracts Setup
- ✓ Both the minter and MGRO should have the managementFacet contract set

## ERC20 Token Minting and Burning
- ✓ The ERC20 Contract should only allow minting if it is called by the management contract
- ✓ Once the Management Contract mints, the owner address balance should be increased, and the stats updated
- ✓ User Should be able to burn tokens from the management contract
- ✓ Should not change the stats values if the tokens are transferred (44ms)
- ✓ Users can burn tokens only through the management contract

## Base URI Management
- ✓ Should allow owner to set the base URIs
- ✓ Should not allow more than 3 URIs

## NFT Minting and URI Updates
- ✓ Users should be able to mint NFTs, and tokenId added to array of owned tokens
- ✓ Check for the Minted NFT to be set to the baseURI[0] on mint
- ✓ Should update the URI if the minted is greater than burnt (53ms)
- ✓ Should update the URI if the minted is greater than burnt and minted is greater than 100 (45ms)
- ✓ Should update the URI if the minted is greater than burnt and minted is greater than 150 (65ms)
- ✓ Should update the URI if the burnt is greater than minted (82ms)

## TGN Test
### Token Test
- ✓ Should allow owner to mint tokens
- ✓ Users can transfer tokens
- ✓ Should have the correct name, symbol, and decimals
- ✓ Users can approve token usage by another contract
- ✓ Owner can mint 300M Tokens max
- ✓ Should send the staking address tokens

## Pre-Staking Vault Tests
- ✓ Should take in addresses and amounts for the pre-stake
- ✓ Should not allow a user to claim until 15th January (50ms)
- ✓ Should not allow a user to claim without an allocation
- ✓ Should not allow users to claim more than once (38ms)
