// SPDX-License-Identifier: GPL
pragma solidity 0.8.24;

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

/**
 * @title Diamond
 * @notice Main Diamond proxy contract implementing EIP-2535 Diamond Standard
 * @dev Delegates calls to facet contracts using delegatecall
 */
contract Diamond {
    // Custom errors for gas efficiency
    error InvalidAddress();
    error NoCode();
    error FunctionDoesNotExist();

    event DiamondInitialized(address indexed owner, address indexed diamondCutFacet);
    event EtherReceived(address indexed sender, uint256 amount);

    /**
     * @notice Initializes the Diamond contract
     * @param _contractOwner The owner address of the Diamond
     * @param _diamondCutFacet The address of the DiamondCut facet
     */
    constructor(address _contractOwner, address _diamondCutFacet) payable {        
        if (_contractOwner == address(0)) revert InvalidAddress();
        if (_diamondCutFacet == address(0)) revert InvalidAddress();
        
        // Verify facet has code using modern approach
        if (_diamondCutFacet.code.length == 0) revert NoCode();

        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet, 
            action: IDiamondCut.FacetCutAction.Add, 
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");

        emit DiamondInitialized(_contractOwner, _diamondCutFacet);
    }

    /**
     * @notice Fallback function to delegate calls to facets
     * @dev Uses delegatecall to execute function on the appropriate facet
     */
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) revert FunctionDoesNotExist();
        
        // Verify facet still has code (not selfdestructed) using modern approach
        if (facet.code.length == 0) revert NoCode();
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
     * @notice Receive function to accept Ether
     */
    receive() external payable { 
        emit EtherReceived(msg.sender, msg.value); 
    }
}
