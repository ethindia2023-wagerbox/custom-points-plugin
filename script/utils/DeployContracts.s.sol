// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {SafeProtocolRegistry} from "@safe/SafeProtocolRegistry.sol";
import {SafeProtocolManager} from "@safe/SafeProtocolManager.sol";
import {PointCardPlugin} from "../../src/PointCardPlugin.sol";

import {Wagerbox} from "../../src/ERC20/Wagerbox.sol";

import {MockPointProtocol} from "../../src/protocol/MockPointProtocol.sol";

import { console2 } from "lib/forge-std/src/console2.sol";

contract DeployContracts is Script {
    function run(address owner) public returns (PointCardPlugin, SafeProtocolManager, SafeProtocolRegistry) {
        console2.log("DeployContracts.s.sol: run===================");
        SafeProtocolRegistry registry = new SafeProtocolRegistry(owner);
        console2.log("SafeProtocolRegistry address=", address(registry));
        SafeProtocolManager manager = new SafeProtocolManager(owner, address(registry));
        console2.log("SafeProtocolManager address=", address(manager));
        Wagerbox token = new Wagerbox();
        console2.log("WagBox address=", address(token));
        MockPointProtocol protocol = new MockPointProtocol(token);
        console2.log("MockPointProtocol address=", address(protocol));
        token.mint(address(protocol), 1000000);
        PointCardPlugin plugin = new PointCardPlugin(address(protocol));
        console2.log("PointCardPlugin address=", address(plugin));
        console2.log("DeployContracts.s.sol: run=================== end");
        return (plugin, manager, registry);
    }
}
