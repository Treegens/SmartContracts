# Batch Size Gas Calculation

## Chain Specifications

| Chain | Block Gas Limit | Gas Price | L1 Type |
|-------|----------------|-----------|---------|
| **Ethereum Mainnet** | ~30,000,000 | High (15-50 gwei) | L1 |
| **Base Mainnet** | ~30,000,000 | Low (~0.001 gwei) | L2 (Optimistic Rollup) |

## Gas Cost Per Operation

### updateURIsByAddress() Gas Breakdown

For each token in the batch:
1. **tokenOfOwnerByIndex()** - ~3,000 gas (reads from ERC721Enumerable)
2. **_setTokenURI()** breakdown:
   - `_requireOwned()` - ~2,500 gas (ownership check)
   - `SSTORE` (URI storage write):
     - New slot: ~20,000 gas
     - Update existing: ~2,900 gas
   - String storage (varies by length):
     - Short URI (~50 chars): ~3,000 gas
     - Long URI (~100 chars): ~6,000 gas
   - `emit MetadataUpdate()` - ~1,500 gas

**Per-iteration cost:**
- **Worst case (new URI):** ~35,000 gas
- **Best case (update short URI):** ~12,000 gas
- **Average case:** ~20,000 gas

### batchMetadataUpdate() Gas Breakdown

Much cheaper - only emits events:
- **Per token:** ~1,500 gas
- **100 tokens:** ~150,000 gas
- **Safe limit:** 500+ tokens

## Recommended Batch Sizes

### For Ethereum (TreegenNFT)
```
Block Gas Limit: 30,000,000
Safe tx limit: ~10,000,000 (33% of block, leaves room for other operations)

updateURIsByAddress:
- Using average 20,000 gas/token
- 10,000,000 ÷ 20,000 = 500 tokens
- Recommended: 200 tokens (with safety margin)

batchMetadataUpdate:
- Using 1,500 gas/token  
- 10,000,000 ÷ 1,500 = 6,666 tokens
- Recommended: 1,000 tokens
```

### For Base (TreegenNFT_Canonical)
```
Block Gas Limit: 30,000,000 (same as Ethereum)
Additional benefits:
- Much cheaper gas (but same limit)
- Optimistic rollup advantages

updateURIsByAddress:
- Same gas mechanics as Ethereum
- Recommended: 200 tokens (gas limit is the same)

batchMetadataUpdate:
- Recommended: 1,000 tokens
```

## Why Not Just Use Block Gas Limit?

1. **Transaction competition:** Other txs need room in the block
2. **RPC limits:** Some RPC providers have lower gas limits (5-10M)
3. **User experience:** Smaller batches = faster confirmations
4. **Retry logic:** If tx fails, smaller batch easier to retry

## Recommendation by Function

| Function | Ethereum | Base | Reasoning |
|----------|----------|------|-----------|
| `updateURIsByAddress` | 100 | 100 | Storage-heavy, conservative |
| `batchMetadataUpdate` | 500 | 500 | Event-only, can be higher |

## Test to Find Your Optimal Value

```solidity
// Add this to your test file
function test_GasCost_UpdateURIs() public {
    // Setup
    address user = address(0x123);
    string[] memory uris = new string[](10);
    for (uint i = 0; i < 10; i++) {
        uris[i] = "ipfs://QmXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/metadata/";
        // Mint NFTs to user first
    }
    
    // Measure gas
    uint256 gasBefore = gasleft();
    nft.updateURIsByAddress(user, uris);
    uint256 gasUsed = gasBefore - gasleft();
    
    console.log("Gas per 10 tokens:", gasUsed);
    console.log("Gas per token:", gasUsed / 10);
    console.log("Safe batch size:", 10_000_000 / (gasUsed / 10));
}
```

## Dynamic Approach (Recommended)

Instead of hardcoded limits, make it configurable:

```solidity
// In contract
uint256 public maxBatchSize = 100;  // Default conservative

function setMaxBatchSize(uint256 _newSize) external onlyOwner {
    require(_newSize > 0 && _newSize <= 1000, "Invalid batch size");
    maxBatchSize = _newSize;
}

function updateURIsByAddress(address owner, string[] memory uris) external onlyNFTUpdater {
    require(uris.length <= maxBatchSize, "Batch size exceeds limit");
    // ...
}
```

This allows you to:
1. Start conservative (100)
2. Test in production
3. Increase if safe
4. Decrease if hitting issues

