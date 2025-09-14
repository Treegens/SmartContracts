// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

interface IBaseMgroOapp {
    function quoteMint(uint32 _dstEid, address _user, uint256 _amount, bool _payInLzToken)
        external
        view
        returns (MessagingFee memory);

    function quoteBurn(uint32 _dstEid, address _user, uint256 _amount, bool _payInLzToken)
        external
        view
        returns (MessagingFee memory);

    function sendMint(uint32 _dstEid, address _user, uint256 _amount, bool _payInLzToken)
        external
        payable
        returns (MessagingReceipt memory);

    function sendBurn(uint32 _dstEid, address _user, uint256 _amount, bool _payInLzToken)
        external
        payable
        returns (MessagingReceipt memory);
}


