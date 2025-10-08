// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;



import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";


contract Diamond {    

    event DiamondInitialized(address indexed owner, address indexed diamondCutFacet);
    event EtherReceived(address indexed sender, uint256 amount);

    constructor(address _contractOwner, address _diamondCutFacet) payable {        
        require(_contractOwner != address(0), "Diamond: owner is zero address");
        require(_diamondCutFacet != address(0), "Diamond: cut facet is zero address");
        // verify facet has code
        uint256 facetSize;
        assembly { facetSize := extcodesize(_diamondCutFacet) }
        require(facetSize > 0, "Diamond: cut facet has no code");

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

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // verify facet still has code (not selfdestructed)
        uint256 facetSize;
        assembly { facetSize := extcodesize(facet) }
        require(facetSize > 0, "Diamond: Facet has no code");
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

    receive() external payable { emit EtherReceived(msg.sender, msg.value); }
}
