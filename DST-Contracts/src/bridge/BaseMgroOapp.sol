// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OApp, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IManagementAck {
    function confirmMint(address _receiver, uint256 _tokens) external;
    function confirmBurn(address _user, uint256 _tokens) external;
}

contract BaseMgroOapp is Ownable, OApp {
    error Unauthorized();

    address public management; // Diamond management contract on Base allowed to send msgs

    enum Operation {
        Mint,
        Burn
    }

    // Ack messages coming back from Celo
    enum Ack {
        MintOk,
        BurnOk
    }

    event ManagementUpdated(address management);

    constructor(address _endpoint, address _delegate, address _management) OApp(_endpoint, _delegate) Ownable(_delegate) {
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

    // -------- quote helpers for forward messages --------
    function quoteMint(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(Operation.Mint, _user, _amount);
        return _quote(_dstEid, payload, bytes(""), _payInLzToken);
    }

    function quoteBurn(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(Operation.Burn, _user, _amount);
        return _quote(_dstEid, payload, bytes(""), _payInLzToken);
    }

    // -------- send forward ops to Celo --------
    function sendMint(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external payable onlyManagement returns (MessagingReceipt memory receipt) {
        require(_user != address(0), "Invalid recipient");
        require(_amount > 0, "Invalid amount");
        bytes memory payload = abi.encode(Operation.Mint, _user, _amount);
        MessagingFee memory fee = _quote(_dstEid, payload, bytes(""), _payInLzToken);
        receipt = _lzSend(_dstEid, payload, bytes(""), fee, msg.sender);
    }

    function sendBurn(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external payable onlyManagement returns (MessagingReceipt memory receipt) {
        require(_user != address(0), "Invalid user");
        require(_amount > 0, "Invalid amount");
        bytes memory payload = abi.encode(Operation.Burn, _user, _amount);
        MessagingFee memory fee = _quote(_dstEid, payload, bytes(""), _payInLzToken);
        receipt = _lzSend(_dstEid, payload, bytes(""), fee, msg.sender);
    }

    // -------- receive ACKs from Celo and forward to management --------
    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (Ack ackType, address user, uint256 amount) = abi.decode(_message, (Ack, address, uint256));
        if (ackType == Ack.MintOk) {
            IManagementAck(management).confirmMint(user, amount);
        } else if (ackType == Ack.BurnOk) {
            IManagementAck(management).confirmBurn(user, amount);
        }
    }
}
