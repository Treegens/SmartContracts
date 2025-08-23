// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

// Mock messenger for testing
contract MockMessenger {
    
    event MockMintSent(uint32 dstEid, address user, uint256 amount);
    event MockBurnSent(uint32 dstEid, address user, uint256 amount);
    
    function sendMint(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bytes calldata _options,
        bool _payInLzToken
    ) external payable returns (bytes memory) {
        emit MockMintSent(_dstEid, _user, _amount);
        return abi.encodePacked("mock-receipt");
    }
    
    function sendBurn(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bytes calldata _options,
        bool _payInLzToken
    ) external payable returns (bytes memory) {
        emit MockBurnSent(_dstEid, _user, _amount);
        return abi.encodePacked("mock-receipt");
    }
}
