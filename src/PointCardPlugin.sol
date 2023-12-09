// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe/interfaces/Manager.sol";
import {OwnerManager} from "@safe/base/OwnerManager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe/DataTypes.sol";
import {IWagerBoxProtocol} from "./protocol/WagerBoxProtocol.sol";

import { console2 } from "lib/forge-std/src/console2.sol";


contract PointCardPlugin is BasePluginWithEventMetadata {

    IWagerBoxProtocol internal pointManagerProtocol;   // issue point

    bytes4 erc20transferFunction = bytes4(keccak256(bytes("transfer(address,uint256)")));

    error RequireCalledByOwner(address manager, address sender);
    error RequireTransferTransaction();

    constructor(address _pointManagerProtocol)
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "PointCardPlugin",
                version: "1.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: ""
            })
        ){
            // todo: check EIP-165 interface
            pointManagerProtocol = IWagerBoxProtocol(_pointManagerProtocol);
        }
    
    function subscribe(address wallet) public {
        pointManagerProtocol.subscribe(wallet);
    }

    function executeFromPlugin(
        ISafeProtocolManager manager,
        ISafe safe,
        SafeTransaction calldata safetx
    ) external returns (bytes[] memory data) {
        if (!(OwnerManager(address(safe)).isOwner(msg.sender))) {
            revert RequireCalledByOwner(address(safe), msg.sender);
        }

        SafeProtocolAction[] memory actions = safetx.actions;
        uint256 length = actions.length;
        for (uint256 i = 0; i < length; i++) {
            bytes4 fs;
            address to;
            address token;
            uint256 value;
            if (actions[i].value != 0) {
                to = actions[i].to;
                token = address(0);
                value = actions[i].value;
            } else if (actions[i].data.length != 0) {
                bytes memory actionData = actions[i].data;
                assembly {
                    fs := mload(add(actionData, 0x20))
                    to := mload(add(actionData, 0x24))
                    value := mload(add(actionData, 0x44))
                }
                token = actions[i].to;
            }
            console2.log("fs==========");
            console2.logBytes4(erc20transferFunction);
            console2.log("actual=");
            console2.logBytes4(fs);

            console2.log("to= %a", to);
            console2.log("value= %d", value);

            if (value == 0 && fs != erc20transferFunction) {
                revert RequireTransferTransaction();
            }

            if (pointManagerProtocol.isSupportingPaymentAddress(to)) {
                console2.log("issue point ==== ");
                pointManagerProtocol.issuePoint(address(safe), token, value);
            }
        }
        (data) = manager.executeTransaction(safe, safetx);
    }
    
}
