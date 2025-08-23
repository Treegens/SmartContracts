// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import "@layerzerolabs/oft-evm/contracts/OFT.sol";

contract MGRO is OFT {
    error InvalidInput();

    address public management;

    // Canonical MGRO on Celo; bridging via OFT is built-in but peers can remain unset until needed.
    constructor(address _lzEndpoint, address _delegate)
        OFT("MGRO", "MGRO", _lzEndpoint, _delegate)
    {
        _transferOwnership(_delegate);
    }

    modifier onlyManagement() {
        require(msg.sender == management, "Unauthorized");
        _;
    }

    function setManagementContract(address _address) public onlyOwner {
        require(_address != address(0));
        management = _address;
    }

    // Supply control: ONLY via cross-chain receiver (set as management)
    function mintTokens(address _receiver, uint _tokens) external onlyManagement {
        if (_receiver == address(0)) revert InvalidInput();
        require(_tokens > 0, "Invalid Token Number");
        _mint(_receiver, _tokens);
    }

    function burnTokens(address _address, uint tokenAmt) external onlyManagement {
        require(balanceOf(_address) >= tokenAmt, "Not Enough tokens to burn");
        _burn(_address, tokenAmt);
    }
}

interface IMGro {
    function mintTokens(address _receiver, uint _tokens) external;
    function burnTokens(address _address, uint tokenAmt) external;
}
