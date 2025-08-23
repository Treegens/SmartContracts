// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CeloMgroReceiver } from "../bridge/CeloMgroReceiver.sol";
import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppReceiver.sol";

contract CeloMgroReceiverHarness is CeloMgroReceiver {
    constructor(address _endpoint, address _delegate, address _mgro)
        CeloMgroReceiver(_endpoint, _delegate, _mgro)
    {}

    // Expose internal _lzReceive for testing with calldata parameters
    function hReceive(Origin calldata origin, bytes32 guid, bytes calldata message, bytes calldata extra) external {
        _lzReceive(origin, guid, message, address(0), extra);
    }
}


