// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "./BaseTreePlantingNFT.sol";

/**
 * @title MangroveTreeNFT
 * @author Treegens Foundation
 * @notice ERC-721 certificates for verified mangrove tree-planting submissions.
 */
contract MangroveTreeNFT is BaseTreePlantingNFT {
    constructor() BaseTreePlantingNFT("Treegens Mangrove Planting", "TGMANGROVE") {}
}
