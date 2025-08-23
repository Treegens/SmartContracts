// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MessagingParams, MessagingFee, MessagingReceipt, Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

// Minimal mock of the LayerZero Endpoint V2 used by OAppCore/OAppSender/OAppReceiver during tests
contract MockLzEndpointV2 {
    address public delegate;
    address public lzTokenAddress;
    uint64 public nextNonce;

    event DelegateSet(address delegate);

    function setDelegate(address _delegate) external {
        delegate = _delegate;
        emit DelegateSet(_delegate);
    }

    function quote(MessagingParams calldata /*_params*/, address /*_sender*/) external pure returns (MessagingFee memory fee) {
        // Return zero fees for tests
        fee = MessagingFee({ nativeFee: 0, lzTokenFee: 0 });
    }

    function send(
        MessagingParams calldata /*_params*/,
        address /*_refundAddress*/
    ) external payable returns (MessagingReceipt memory receipt) {
        // Echo back a dummy receipt; record the msg.value as nativeFee in the receipt
        receipt = MessagingReceipt({ guid: bytes32(uint256(0x1234)), nonce: nextNonce++, fee: MessagingFee({ nativeFee: msg.value, lzTokenFee: 0 }) });
    }

    function setLzToken(address _lzToken) external {
        lzTokenAddress = _lzToken;
    }

    function lzToken() external view returns (address) {
        return lzTokenAddress;
    }

    function nativeToken() external pure returns (address) {
        return address(0);
    }

    // Unused in tests but included for completeness
    function verify(Origin calldata /*_origin*/, address /*_receiver*/, bytes32 /*_payloadHash*/) external pure {}
    function verifiable(Origin calldata /*_origin*/, address /*_receiver*/) external pure returns (bool) { return true; }
    function initializable(Origin calldata /*_origin*/, address /*_receiver*/) external pure returns (bool) { return true; }
    function lzReceive(Origin calldata /*_origin*/, address /*_receiver*/, bytes32 /*_guid*/, bytes calldata /*_message*/, bytes calldata /*_extraData*/) external payable {}
    function clear(address /*_oapp*/, Origin calldata /*_origin*/, bytes32 /*_guid*/, bytes calldata /*_message*/) external pure {}
}


