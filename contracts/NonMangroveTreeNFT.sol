// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "./BaseTreePlantingNFT.sol";

/**
 * @title NonMangroveTreeNFT
 * @author Treegens Foundation
 * @notice ERC-721 certificates for verified non-mangrove tree-planting submissions.
 */
contract NonMangroveTreeNFT is BaseTreePlantingNFT {
    constructor() BaseTreePlantingNFT("Treegens Tree Planting", "TGTREE") {}
}
