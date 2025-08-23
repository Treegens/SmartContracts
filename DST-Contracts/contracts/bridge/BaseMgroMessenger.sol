// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract BaseMgroMessenger is OAppSender {
    error Unauthorized();

    address public management; // Diamond management contract on Base allowed to send msgs

    enum Operation {
        Mint,
        Burn
    }

    event ManagementUpdated(address management);

    constructor(address _endpoint, address _delegate, address _management) OAppCore(_endpoint, _delegate) {
        management = _management;
        emit ManagementUpdated(_management);
    }

    modifier onlyManagement() {
        if (msg.sender != management) revert Unauthorized();
        _;
    }

    function setManagement(address _management) external onlyOwner {
        management = _management;
        emit ManagementUpdated(_management);
    }

    function quoteMint(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(Operation.Mint, _user, _amount);
        return _quote(_dstEid, payload, _options, _payInLzToken);
    }

    function quoteBurn(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(Operation.Burn, _user, _amount);
        return _quote(_dstEid, payload, _options, _payInLzToken);
    }

    function sendMint(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bytes calldata _options,
        bool _payInLzToken
    ) external payable onlyManagement returns (MessagingReceipt memory receipt) {
        bytes memory payload = abi.encode(Operation.Mint, _user, _amount);
        MessagingFee memory fee = _quote(_dstEid, payload, _options, _payInLzToken);
        // OAppSender enforces exact native fee via _payNative
        receipt = _lzSend(_dstEid, payload, _options, fee, msg.sender);
    }

    function sendBurn(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bytes calldata _options,
        bool _payInLzToken
    ) external payable onlyManagement returns (MessagingReceipt memory receipt) {
        bytes memory payload = abi.encode(Operation.Burn, _user, _amount);
        MessagingFee memory fee = _quote(_dstEid, payload, _options, _payInLzToken);
        receipt = _lzSend(_dstEid, payload, _options, fee, msg.sender);
    }
}
