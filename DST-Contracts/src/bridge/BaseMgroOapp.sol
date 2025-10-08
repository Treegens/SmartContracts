// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OApp, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";

interface IManagementAck {
    function confirmMint(address _receiver, uint256 _tokens) external;
    function confirmBurn(address _user, uint256 _tokens) external;
}

contract BaseMgroOapp is Ownable, OApp, OAppOptionsType3, Pausable, ReentrancyGuard {
    error Unauthorized();
    error ZeroAddress();
    error InvalidAmount();
    error InvalidDestinationEid();
    error EnforcedOptionsNotSet();

    address public management; // Diamond management contract on Base allowed to send msgs
    address public pendingManagement; // Pending management for two-step transfer

    // Message type used for standard forward operations (Mint/Burn)
    uint16 internal constant MSG_TYPE_FORWARD = 1;

    enum Operation {
        Mint,
        Burn
    }

    // Ack messages coming back from Celo
    enum Ack {
        MintOk,
        BurnOk
    }

    // Events
    event ManagementUpdated(address indexed oldManagement, address indexed newManagement);
    event ManagementTransferProposed(address indexed currentManagement, address indexed pendingManagement);
    event MintSent(uint32 indexed dstEid, address indexed user, uint256 amount, uint256 nativeFee);
    event BurnSent(uint32 indexed dstEid, address indexed user, uint256 amount, uint256 nativeFee);
    event AckReceived(Ack indexed ackType, address indexed user, uint256 amount);
    event AckForwardingFailed(Ack indexed ackType, address indexed user, uint256 amount, bytes reason);

    constructor(address _endpoint, address _delegate, address _management) OApp(_endpoint, _delegate) Ownable(_delegate) {
        if (_endpoint == address(0)) revert ZeroAddress();
        if (_delegate == address(0)) revert ZeroAddress();
        if (_management == address(0)) revert ZeroAddress();
        
        management = _management;
        emit ManagementUpdated(address(0), _management);
    }

    modifier onlyManagement() {
        if (msg.sender != management) revert Unauthorized();
        _;
    }

    /**
     * @notice Propose a new management address (two-step transfer)
     * @param _newManagement The proposed new management address
     */
    function proposeManagementTransfer(address _newManagement) external onlyOwner {
        if (_newManagement == address(0)) revert ZeroAddress();
        pendingManagement = _newManagement;
        emit ManagementTransferProposed(management, _newManagement);
    }

    /**
     * @notice Accept management transfer (must be called by pending management)
     */
    function acceptManagementTransfer() external {
        if (msg.sender != pendingManagement) revert Unauthorized();
        
        address oldManagement = management;
        management = pendingManagement;
        pendingManagement = address(0);
        
        emit ManagementUpdated(oldManagement, management);
    }

    /**
     * @notice Cancel pending management transfer
     */
    function cancelManagementTransfer() external onlyOwner {
        pendingManagement = address(0);
        emit ManagementTransferProposed(management, address(0));
    }

    /**
     * @notice Emergency pause function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // -------- Internal validation helpers --------
    
    /**
     * @notice Validate enforced options are set for the destination EID
     * @param _dstEid Destination endpoint ID
     */
    function _validateEnforcedOptions(uint32 _dstEid) internal view {
        bytes memory options = enforcedOptions[_dstEid][MSG_TYPE_FORWARD];
        if (options.length == 0) revert EnforcedOptionsNotSet();
    }

    /**
     * @notice Validate user address and amount
     * @param _user User address
     * @param _amount Token amount
     */
    function _validateUserAndAmount(address _user, uint256 _amount) internal pure {
        if (_user == address(0)) revert ZeroAddress();
        if (_amount == 0) revert InvalidAmount();
    }

    // -------- quote helpers for forward messages --------
    function quoteMint(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        _validateUserAndAmount(_user, _amount);
        _validateEnforcedOptions(_dstEid);
        
        bytes memory payload = abi.encode(Operation.Mint, _user, _amount);
        bytes memory options = enforcedOptions[_dstEid][MSG_TYPE_FORWARD];
        return _quote(_dstEid, payload, options, _payInLzToken);
    }

    function quoteBurn(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        _validateUserAndAmount(_user, _amount);
        _validateEnforcedOptions(_dstEid);
        
        bytes memory payload = abi.encode(Operation.Burn, _user, _amount);
        bytes memory options = enforcedOptions[_dstEid][MSG_TYPE_FORWARD];
        return _quote(_dstEid, payload, options, _payInLzToken);
    }

    // -------- send forward ops to Celo --------
    
    /**
     * @notice Send a mint instruction to Celo
     * @param _dstEid Destination endpoint ID (Celo)
     * @param _user User to receive minted tokens
     * @param _amount Amount to mint
     * @param _payInLzToken Whether to pay fee in LZ token
     * @return receipt Messaging receipt
     */
    function sendMint(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external payable onlyManagement whenNotPaused nonReentrant returns (MessagingReceipt memory receipt) {
        _validateUserAndAmount(_user, _amount);
        _validateEnforcedOptions(_dstEid);
        
        bytes memory payload = abi.encode(Operation.Mint, _user, _amount);
        bytes memory options = enforcedOptions[_dstEid][MSG_TYPE_FORWARD];
        MessagingFee memory fee = _quote(_dstEid, payload, options, _payInLzToken);
        
        receipt = _lzSend(_dstEid, payload, options, fee, msg.sender);
        
        emit MintSent(_dstEid, _user, _amount, fee.nativeFee);
    }

    /**
     * @notice Send a burn instruction to Celo
     * @param _dstEid Destination endpoint ID (Celo)
     * @param _user User whose tokens will be burned
     * @param _amount Amount to burn
     * @param _payInLzToken Whether to pay fee in LZ token
     * @return receipt Messaging receipt
     */
    function sendBurn(
        uint32 _dstEid,
        address _user,
        uint256 _amount,
        bool _payInLzToken
    ) external payable onlyManagement whenNotPaused nonReentrant returns (MessagingReceipt memory receipt) {
        _validateUserAndAmount(_user, _amount);
        _validateEnforcedOptions(_dstEid);
        
        bytes memory payload = abi.encode(Operation.Burn, _user, _amount);
        bytes memory options = enforcedOptions[_dstEid][MSG_TYPE_FORWARD];
        MessagingFee memory fee = _quote(_dstEid, payload, options, _payInLzToken);
        
        receipt = _lzSend(_dstEid, payload, options, fee, msg.sender);
        
        emit BurnSent(_dstEid, _user, _amount, fee.nativeFee);
    }

    // -------- receive ACKs from Celo and forward to management --------
    
    /**
     * @notice Receive and process ACK messages from Celo
     * @dev Uses try/catch to prevent reverts in management from stalling message queue
     * @param _message Encoded ACK message
     */
    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (Ack ackType, address user, uint256 amount) = abi.decode(_message, (Ack, address, uint256));
        
        // Use try/catch to prevent reverts in management contract from stalling the message queue
        if (ackType == Ack.MintOk) {
            try IManagementAck(management).confirmMint(user, amount) {
                emit AckReceived(ackType, user, amount);
            } catch (bytes memory reason) {
                emit AckForwardingFailed(ackType, user, amount, reason);
            }
        } else if (ackType == Ack.BurnOk) {
            try IManagementAck(management).confirmBurn(user, amount) {
                emit AckReceived(ackType, user, amount);
            } catch (bytes memory reason) {
                emit AckForwardingFailed(ackType, user, amount, reason);
            }
        }
    }
}
