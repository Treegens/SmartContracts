// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

interface IBaseMgroMessenger {
    function quoteMint(uint32 _dstEid, address _user, uint256 _amount, bytes calldata _options, bool _payInLzToken)
        external
        view
        returns (MessagingFee memory);

    function quoteBurn(uint32 _dstEid, address _user, uint256 _amount, bytes calldata _options, bool _payInLzToken)
        external
        view
        returns (MessagingFee memory);

    function sendMint(uint32 _dstEid, address _user, uint256 _amount, bytes calldata _options, bool _payInLzToken)
        external
        payable
        returns (MessagingReceipt memory);

    function sendBurn(uint32 _dstEid, address _user, uint256 _amount, bytes calldata _options, bool _payInLzToken)
        external
        payable
        returns (MessagingReceipt memory);
}


