# DSST

ARAGON DAO governance tested and working well

✔ Both the minter and MGRO should have the MGMT contract set
    ✔ The ERC20 Contract should only allow minting if it is called by the management contract 
    ✔ Once the Management Contract mints, the owner address balance should be increased, and the stats updated
    ✔ User Should be able to burn tokens from the management contract 
    ✔ Should not change the stats values if the tokens are transferred 
    ✔ Users can burn tokens only through the management contract
    ✔ Should allow owner to set the base URIs
    ✔ Should not allow more than 3 URIs
    ✔ Users should be able to mint NFTs, and tokenId added to array of owned tokens
    ✔ Check for the Minted NFT to be set to the baseURI[0] on mint
    ✔ Should update the URI if the minted is greater than burnt 
    ✔ Should update the URI if the burnt is greater than minted 

    
 TGN Test
    ✔ Should allow owner to mint tokens
    ✔ Users can transfer tokens (39ms)
    ✔ Should have the correct name, symbol and decimals
    ✔ Users can approve token usage by another contract
    ✔ Owner can mint 300M Tokens max (104ms)

Staking Test
    ✔ Should send the staking address tokens
    ✔ Should take in addresses and amounts for the pre-stake (39ms)
    ✔ Should not allow a user to claim until 15th January (55ms)
    ✔ Should not allow a user to claim without an allocation
    ✔ Should not allow users to claim more than once (44ms)



