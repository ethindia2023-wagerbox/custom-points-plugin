// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {SafeProtocolManager} from "@safe/SafeProtocolManager.sol";
import {SafeProtocolRegistry} from "@safe/SafeProtocolRegistry.sol";
import {Safe} from "@safe/Safe.sol";
import {PointCardPlugin} from "../src/PointCardPlugin.sol";
import {DeployContracts} from "./utils/DeployContracts.s.sol";
import {SafeTxConfig} from "./utils/SafeTxConfig.s.sol";

import {Wagerbox} from "../src/ERC20/Wagerbox.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe/DataTypes.sol";
import {MockPointProtocol} from "../src/protocol/MockPointProtocol.sol";
import {ISafe} from "@safe/interfaces/Accounts.sol";
import {MockPointProtocol} from "../src/protocol/MockPointProtocol.sol";

import { console2 } from "lib/forge-std/src/console2.sol";

contract Setup is Script {
    error SafeTxFailure(bytes reason);

    Safe safe = Safe(payable(vm.envAddress("SAFE_ADDRESS")));
    address owner = vm.envAddress("SAFE_OWNER_ADDRESS");
    SafeTxConfig safeTxConfig = new SafeTxConfig();
    SafeTxConfig.Config config = safeTxConfig.run();

    SafeProtocolManager manager = SafeProtocolManager(address(0xB5A92EB54CD44C87875Ec8d4e166708ec6CCa61F));
    MockPointProtocol protocol = MockPointProtocol(address(0x45FF4CCF804572B3bA17081348abf871D8A2e280));
    PointCardPlugin plugin = PointCardPlugin(address(0x091578BAe1A95c0322441509CCA99fC3248F9A5A));


    function getTransactionHash(address _to, bytes memory _data) public view returns (bytes32) {
        return safe.getTransactionHash(
            _to,
            config.value,
            _data,
            config.operation,
            config.safeTxGas,
            config.baseGas,
            config.gasPrice,
            config.gasToken,
            config.refundReceiver,
            safe.nonce()
        );
    }

    function sendSafeTx(address _to, bytes memory _data, bytes memory sig) public {
        try safe.execTransaction(
            _to,
            config.value,
            _data,
            config.operation,
            config.safeTxGas,
            config.baseGas,
            config.gasPrice,
            config.gasToken,
            config.refundReceiver,
            sig //sig
        ){} catch (bytes memory reason) {
            revert SafeTxFailure(reason);
        }
    }

    function run() public {
        console2.log("Setup.s.sol: run================================- ");

        vm.startBroadcast(vm.envUint("SAFE_OWNER_PRIVATE_KEY"));

        bytes32 txHash = getTransactionHash(
            address(plugin),
            abi.encodeWithSignature(
                "subscribe(address)",
                address(safe)
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("SAFE_OWNER_PRIVATE_KEY"),
            txHash
        );
        sendSafeTx(
            address(plugin),
            abi.encodeWithSignature("subscribe(address)", address(safe)),
            abi.encodePacked(r, s, v)
        );

        console2.log("Setup.s.sol: subscribed ");
        address supportingPaymentAddress = address(0x02FA108b1B8707a250420779eB5e229DC111453B);
        // add dealer
        console2.log("Setup.s.sol: addSupportingpaymentaaddress ");
        protocol.isSupportingPaymentAddress(address(0x02FA108b1B8707a250420779eB5e229DC111453B));
//        protocol.addSupportingPaymentAddress(address(0x02FA108b1B8707a250420779eB5e229DC111453B));
        console2.log("Setup.s.sol: add supportingPaymentAddress end");

        console2.log("Setup.s.sol: create actions");
        SafeProtocolAction[] memory actions = new SafeProtocolAction[](1);
        actions[0].value = 10;
        actions[0].to = payable(supportingPaymentAddress);

        SafeTransaction memory tx = SafeTransaction({
            actions: actions,
            nonce: safe.nonce(),
            metadataHash: bytes32(0)
        });

        ISafe addressSafe = ISafe(address(safe));
        console2.log("Setup.s.sol: executeFromPlugin=======");
        plugin.executeFromPlugin(manager, addressSafe, tx); 
        
        vm.stopBroadcast();

        console2.log("Setup.s.sol: run================================- END");
    }
}
