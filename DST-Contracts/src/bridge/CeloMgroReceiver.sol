// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OAppReceiver } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppReceiver.sol";
import { OAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppReceiver.sol";
import { MGRO } from "../MGRO.sol";

contract CeloMgroReceiver is OAppReceiver {
    MGRO public mgro;

    enum Operation {
        Mint,
        Burn
    }

    event MgroSet(address mgro);

    constructor(address _endpoint, address _delegate, address _mgro) 
        OAppCore(_endpoint, _delegate) 
    {
        mgro = MGRO(_mgro);
        emit MgroSet(_mgro);
    }

    function setMgro(address _mgro) external onlyOwner {
        mgro = MGRO(_mgro);
        emit MgroSet(_mgro);
    }

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (Operation op, address user, uint256 amount) = abi.decode(_message, (Operation, address, uint256));
        if (op == Operation.Mint) {
            mgro.mintTokens(user, amount);
        } else {
            mgro.burnTokens(user, amount);
        }
        // Optionally: emit events or implement ack logic if needed later
    }
}


