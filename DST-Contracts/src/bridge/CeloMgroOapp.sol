// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { OApp } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppReceiver.sol";
import { MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { MGRO } from "../MGRO.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";

contract CeloMgroOapp is Ownable, OApp, OAppOptionsType3 {
    // Message type used for ACK messages sent back to Base
    uint16 internal constant MSG_TYPE_ACK = 1;

    enum Operation {
        Mint,
        Burn
    }

    // Ack types sent back to Base messenger
    enum Ack {
        MintOk,
        BurnOk
    }

    MGRO public mgro;

    event MgroSet(address mgro);
    event AckSent(uint8 ackType, address user, uint256 amount, uint32 dstEid, uint256 feePaid);
    event AckInsufficientFunds(uint8 ackType, address user, uint256 amount, uint256 requiredFee, uint256 balance);

    // Debug event for LayerZero message parsing
    event DebugLzReceive(bytes message, uint32 srcEid, address sender, bytes32 guid);

    constructor(address _endpoint, address _delegate, address _mgro) 
        OApp(_endpoint, _delegate) 
        Ownable(_delegate)
    {
        mgro = MGRO(_mgro);
        emit MgroSet(_mgro);
    }

    function setMgro(address _mgro) external onlyOwner {
        mgro = MGRO(_mgro);
        emit MgroSet(_mgro);
    }

    function quoteAck(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bytes calldata /*_returnOptions*/,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        bytes memory ack = abi.encode(Ack.MintOk, _user, _amount);
        bytes memory options = enforcedOptions[_dstEid][MSG_TYPE_ACK];
        return _quote(_dstEid, ack, options, _payInLzToken);
    }
    
    function _lzReceive(
        Origin calldata origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (Operation op, address user, uint256 amount) = abi.decode(_message, (Operation, address, uint256));
        
        // Debug event to help troubleshoot message parsing
        emit DebugLzReceive(_message, origin.srcEid, address(uint160(uint256(origin.sender))), _guid);
        
        Ack ackType;
        if (op == Operation.Mint) {
            mgro.mintTokens(user, amount);
            ackType = Ack.MintOk;
        } else {
            mgro.burnTokens(user, amount);
            ackType = Ack.BurnOk;
        }

        bytes memory ack = abi.encode(ackType, user, amount);

        // Fallback to contract balance if no value was forwarded
        bytes memory options = enforcedOptions[origin.srcEid][MSG_TYPE_ACK];
        MessagingFee memory fee = _quote(origin.srcEid, ack, options, false);
        if (address(this).balance >= fee.nativeFee) {
            _lzSend(origin.srcEid, ack, options, fee, address(this));
            emit AckSent(uint8(ackType), user, amount, origin.srcEid, fee.nativeFee);
        } else {
            emit AckInsufficientFunds(uint8(ackType), user, amount, fee.nativeFee, address(this).balance);
        }
    }

    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        require(address(this).balance >= _nativeFee, "Insufficient contract balance for ack fee");
        return _nativeFee;
    }

    // Emergency functions to handle trapped funds
    function withdrawNative(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Native transfer failed");
    }

    function withdrawAllNative() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Native transfer failed");
    }

    // Function to deposit native tokens for ack fees
    receive() external payable {}

    
}

