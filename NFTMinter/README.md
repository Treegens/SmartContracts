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




